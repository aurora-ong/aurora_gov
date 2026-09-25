defmodule AuroraGov.EventHandler.ProposalDiscordHandler do
  @moduledoc """
  Notifica propuestas creadas y resultados de ejecución en Discord.

  La entrega usa una suscripción independiente con consistencia eventual.
  Un envío fallido se reintenta sin confirmar el evento como procesado.
  """

  use Commanded.Event.Handler,
    application: AuroraGov,
    name: "AuroraGov.Discord.ProposalNotifications",
    consistency: :eventual,
    start_from: :current

  require Logger

  alias AuroraGov.Event.{ProposalCreated, ProposalConsumed}

  alias AuroraGov.Integrations.Discord.{
    ProposalData,
    ProposalEmbed,
    WebhookClient
  }

  @retry_delays [1_000, 2_000, 5_000, 10_000, 30_000, 60_000]

  @impl true
  def handle(%ProposalCreated{} = event, metadata) do
    with {:ok, _proposal, opts} <-
           ProposalData.fetch(event.proposal_id, metadata) do
      event
      |> ProposalEmbed.created(opts)
      |> deliver()
    end
  end

  def handle(%ProposalConsumed{} = event, metadata) do
    with {:ok, proposal, opts} <-
           ProposalData.fetch(event.proposal_id, metadata) do
      event
      |> ProposalEmbed.consumed(proposal, opts)
      |> deliver()
    end
  end

  # Los demás eventos, incluido ProposalExecuted, no generan mensajes.
  def handle(_event, _metadata), do: :ok

  defp deliver(embed) do
    case WebhookClient.send_embed(embed) do
      {:ok, :disabled} ->
        # No confirmar una entrega que no se intentó.
        {:error, :notifications_disabled}

      {:ok, message_id} when is_binary(message_id) ->
        :ok

      {:error, _reason} = error ->
        error
    end
  end

  @impl true
  def error({:error, reason}, event, failure_context) do
    context = failure_context.context || %{}
    attempt = Map.get(context, :attempt, 0) + 1
    delay = retry_delay(reason, attempt)

    # No registramos payloads, URLs ni errores que puedan contener secretos.
    Logger.warning(
      "Discord: notificación pendiente " <>
        "proposal_id=#{Map.get(event, :proposal_id)} " <>
        "tipo=#{error_kind(reason)} " <>
        "intento=#{attempt} " <>
        "reintento_ms=#{delay}"
    )

    {:retry, delay, Map.put(context, :attempt, attempt)}
  end

  defp retry_delay({:rate_limited, seconds}, _attempt)
       when is_number(seconds) and seconds >= 0 do
    # Discord informa segundos; Commanded espera milisegundos.
    max(1_000, ceil(seconds * 1_000))
  end

  defp retry_delay(reason, _attempt)
       when reason in [
              :missing_webhook_url,
              :invalid_webhook_url,
              :notifications_disabled,
              :invalid_payload,
              :unexpected_response
            ] do
    60_000
  end

  defp retry_delay({:http_error, _status}, _attempt), do: 60_000

  defp retry_delay(_reason, attempt) do
    index = min(attempt - 1, length(@retry_delays) - 1)
    Enum.at(@retry_delays, index)
  end

  defp error_kind({:rate_limited, _}), do: "rate_limited"
  defp error_kind({:http_error, status}), do: "http_#{status}"
  defp error_kind({:server_error, status}), do: "server_#{status}"
  defp error_kind(reason) when is_atom(reason), do: Atom.to_string(reason)
  defp error_kind(_reason), do: "unexpected_error"
end
