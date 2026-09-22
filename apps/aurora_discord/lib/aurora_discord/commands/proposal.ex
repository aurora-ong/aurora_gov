defmodule AuroraDiscord.Commands.Proposal do
  @moduledoc """
  Maneja el detalle de una propuesta de Aurora desde Discord.

  Puede ser utilizado mediante:

  - `/propuesta id:<proposal_id>`
  - botón `Ver detalle` generado por `/propuestas`

  El canal Discord determina la OU desde la cual
  puede consultarse la propuesta.
  """

  require Logger

  alias AuroraDiscord.Integrations
  alias AuroraGov.Context.ProposalContext

  alias Nostrum.Api.Interaction

  alias Nostrum.Struct.Interaction,
    as: DiscordInteraction

  # ===========================================================================
  # SLASH COMMAND
  # ===========================================================================

  @doc """
  Procesa el comando `/propuesta`.
  """
  def handle(
        %DiscordInteraction{
          data: %{options: options}
        } = interaction
      ) do
    case extract_proposal_id(options) do
      {:ok, proposal_id} ->
        show_proposal(
          interaction,
          proposal_id,
          ephemeral: false
        )

      {:error, :missing_proposal_id} ->
        respond(
          interaction,
          "⚠️ Debés indicar el ID de la propuesta.",
          ephemeral: true
        )
    end
  end

  def handle(%DiscordInteraction{} = interaction) do
    respond(
      interaction,
      "⚠️ No se pudo determinar la propuesta solicitada.",
      ephemeral: true
    )
  end

  # ===========================================================================
  # BUTTON
  # ===========================================================================

  @doc """
  Procesa el botón `Ver detalle` generado por `/propuestas`.

  El detalle se responde como ephemeral para que solamente
  lo vea la persona que hizo clic.
  """
  def handle_button(
        %DiscordInteraction{} = interaction,
        proposal_id
      )
      when is_binary(proposal_id) and
             proposal_id != "" do
    show_proposal(
      interaction,
      proposal_id,
      ephemeral: true
    )
  end

  # ===========================================================================
  # PROPOSAL DETAIL
  # ===========================================================================

  defp show_proposal(
         %DiscordInteraction{
           guild_id: guild_id,
           channel_id: channel_id
         } = interaction,
         proposal_id,
         opts
       )
       when is_integer(guild_id) and
              is_integer(channel_id) do
    guild_id =
      Integer.to_string(guild_id)

    with %{} = binding <-
           Integrations.get_channel_binding_by_channel_id(
             guild_id,
             channel_id
           ),
         %{} = proposal <-
           ProposalContext.get_proposal_by_id(
             proposal_id
           ),
         :ok <-
           validate_proposal_ou(
             proposal,
             binding.ou_id
           ) do
      message =
        build_proposal_message(
          proposal,
          binding.ou_id
        )

      respond(
        interaction,
        message,
        ephemeral:
          Keyword.get(
            opts,
            :ephemeral,
            false
          )
      )
    else
      nil ->
        respond(
          interaction,
          "⚠️ La propuesta solicitada no existe.",
          ephemeral: true
        )

      {:error, :proposal_not_in_ou} ->
        respond(
          interaction,
          """
          ⛔ Esta propuesta no pertenece a la unidad
          asociada a este canal.
          """,
          ephemeral: true
        )

      {:error, reason} ->
        Logger.warning(
          "#{__MODULE__}: error consultando propuesta " <>
            "#{proposal_id}: #{inspect(reason)}"
        )

        respond(
          interaction,
          "⚠️ No se pudo consultar la propuesta.",
          ephemeral: true
        )
    end
  end

  # ===========================================================================
  # VALIDATION
  # ===========================================================================

  defp validate_proposal_ou(
         proposal,
         ou_id
       ) do
    if proposal.proposal_ou_end_id == ou_id do
      :ok
    else
      {:error, :proposal_not_in_ou}
    end
  end

  # ===========================================================================
  # SLASH COMMAND OPTIONS
  # ===========================================================================

  defp extract_proposal_id(options)
       when is_list(options) do
    case Enum.find(
           options,
           fn option ->
             option.name == "id"
           end
         ) do
      %{value: value}
      when is_binary(value) and value != "" ->
        {:ok, value}

      _ ->
        {:error, :missing_proposal_id}
    end
  end

  defp extract_proposal_id(_),
    do: {:error, :missing_proposal_id}

  # ===========================================================================
  # MESSAGE
  # ===========================================================================

  defp build_proposal_message(
         proposal,
         current_ou_id
       ) do
    voting_status =
      ProposalContext.calculate_voting_status(
        proposal
      )

    current_voting_status =
      Map.get(
        voting_status,
        current_ou_id
      )

    """
    📜 **#{safe_value(proposal.proposal_title, "Sin título")}**

    #{truncate(safe_value(proposal.proposal_description, "Sin descripción"), 800)}

    **Estado:** #{humanize_status(proposal.proposal_status)}
    **Autor:** #{resolve_owner_name(proposal)}
    **Unidad:** #{resolve_ou_name(proposal)}
    **ID:** `#{proposal.proposal_id}`

    #{build_voting_status(current_voting_status)}
    """
    |> String.trim()
    |> truncate_discord_message()
  end

  defp build_voting_status(nil) do
    "🗳️ **Votación:** sin información disponible."
  end

  defp build_voting_status(status) do
    """
    🗳️ **Estado de votación**
    Votos emitidos: #{status.current_voters}/#{status.total_voters}
    Puntaje actual: #{status.current_score}
    Puntaje requerido: #{status.required_score}
    """
    |> String.trim()
  end

  # ===========================================================================
  # DISPLAY HELPERS
  # ===========================================================================

  defp resolve_owner_name(proposal) do
    case Map.get(
           proposal,
           :proposal_owner
         ) do
      %{person_name: name}
      when is_binary(name) and
             name != "" ->
        name

      _ ->
        safe_value(
          proposal.proposal_owner_id,
          "Desconocido"
        )
    end
  end

  defp resolve_ou_name(proposal) do
    case Map.get(
           proposal,
           :proposal_ou_end
         ) do
      %{ou_name: name}
      when is_binary(name) and
             name != "" ->
        name

      _ ->
        safe_value(
          proposal.proposal_ou_end_id,
          "Unidad desconocida"
        )
    end
  end

  defp humanize_status(status)
       when is_atom(status) do
    status
    |> Atom.to_string()
    |> humanize_status()
  end

  defp humanize_status(status)
       when is_binary(status) do
    status
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  defp humanize_status(_),
    do: "Desconocido"

  defp safe_value(nil, fallback),
    do: fallback

  defp safe_value("", fallback),
    do: fallback

  defp safe_value(value, _fallback),
    do: to_string(value)

  defp truncate(
         value,
         max_length
       )
       when is_binary(value) do
    if String.length(value) <= max_length do
      value
    else
      String.slice(
        value,
        0,
        max_length - 1
      ) <> "…"
    end
  end

  defp truncate_discord_message(message) do
    max_length = 1_900

    if String.length(message) <= max_length do
      message
    else
      String.slice(
        message,
        0,
        1_880
      ) <>
        "\n\n_Contenido truncado._"
    end
  end

  # ===========================================================================
  # RESPONSE
  # ===========================================================================

  defp respond(
         interaction,
         content,
         opts
       ) do
    ephemeral? =
      Keyword.get(
        opts,
        :ephemeral,
        false
      )

    data =
      %{content: String.trim(content)}
      |> maybe_ephemeral(ephemeral?)

    response = %{
      type: 4,
      data: data
    }

    case Interaction.create_response(
           interaction,
           response
         ) do
      {:ok} ->
        :ok

      {:ok, _response} ->
        :ok

      {:error, reason} ->
        Logger.warning(
          "#{__MODULE__}: no se pudo responder interacción: " <>
            inspect(reason)
        )

        {:error, reason}
    end
  end

  defp maybe_ephemeral(
         data,
         true
       ) do
    Map.put(
      data,
      :flags,
      64
    )
  end

  defp maybe_ephemeral(
         data,
         false
       ),
       do: data
end
