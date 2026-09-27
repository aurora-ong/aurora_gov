defmodule AuroraDiscord.Commands.Proposals do
  @moduledoc """
  Implementación del comando Discord `/propuestas`.

  El canal desde el cual se ejecuta el comando determina
  automáticamente la OU de Aurora asociada.

  El comando consulta las propuestas activas de esa OU y
  permite acceder al detalle mediante botones interactivos.
  """

  require Logger

  alias AuroraDiscord.Integrations
  alias AuroraGov.Context.ProposalContext

  alias Nostrum.Api.Interaction

  alias Nostrum.Struct.Interaction,
    as: DiscordInteraction

  # ===========================================================================
  # COMMAND
  # ===========================================================================

  @doc """
  Procesa el comando `/propuestas`.
  """
  def handle(
        %DiscordInteraction{
          guild_id: guild_id,
          channel_id: channel_id
        } = interaction
      )
      when is_integer(guild_id) and
             is_integer(channel_id) do
    guild_id =
      Integer.to_string(guild_id)

    case Integrations.get_channel_binding_by_channel_id(
           guild_id,
           channel_id
         ) do
      nil ->
        Logger.warning(
          "#{__MODULE__}: canal #{channel_id} no está asociado a ninguna OU"
        )

        respond(
          interaction,
          """
          ⚠️ Este canal no está asociado a ninguna unidad de Aurora.

          El comando `/propuestas` solamente puede utilizarse desde un canal vinculado a una OU.
          """,
          ephemeral: true
        )

      binding ->
        Logger.info(
          "#{__MODULE__}: /propuestas ejecutado para OU #{binding.ou_id}"
        )

        proposals =
          ProposalContext.list_active_proposals_by_ou(
            binding.ou_id
          )

        message =
          build_proposals_message(
            binding.ou_id,
            proposals
          )

        components =
          build_proposal_buttons(
            proposals
          )

        respond(
          interaction,
          message,
          components: components,
          ephemeral: false
        )
    end
  end

  def handle(
        %DiscordInteraction{} = interaction
      ) do
    respond(
      interaction,
      "⚠️ `/propuestas` solamente puede utilizarse dentro del servidor de Aurora.",
      ephemeral: true
    )
  end

  # ===========================================================================
  # COMPONENTS
  # ===========================================================================

  defp build_proposal_buttons([]),
    do: []

  defp build_proposal_buttons(proposals) do
    proposals
    |> Enum.take(10)
    |> Enum.with_index(1)
    |> Enum.map(fn {proposal, index} ->
      %{
        type: 2,
        style: 1,
        label: "#{index}. Ver detalle",
        custom_id:
          "proposal_detail:#{proposal.proposal_id}"
      }
    end)
    |> Enum.chunk_every(5)
    |> Enum.map(fn buttons ->
      %{
        type: 1,
        components: buttons
      }
    end)
  end

  # ===========================================================================
  # MESSAGE BUILDERS
  # ===========================================================================

  defp build_proposals_message(
         ou_id,
         []
       ) do
    """
    📋 **Propuestas de Aurora**

    Actualmente no hay propuestas activas en:

    **#{ou_id}**
    """
    |> String.trim()
  end

  defp build_proposals_message(
         ou_id,
         proposals
       ) do
    visible_proposals =
      Enum.take(
        proposals,
        10
      )

    proposal_lines =
      visible_proposals
      |> Enum.with_index(1)
      |> Enum.map_join(
        "\n\n",
        fn {proposal, index} ->
          build_proposal_line(
            proposal,
            index
          )
        end
      )

    remaining =
      length(proposals) -
        length(visible_proposals)

    footer =
      if remaining > 0 do
        """

        _Hay #{remaining} propuesta(s) activa(s) adicional(es)._
        """
      else
        ""
      end

    """
    📋 **Propuestas activas**

    Unidad: **#{ou_id}**

    #{proposal_lines}
    #{footer}
    """
    |> String.trim()
    |> truncate_discord_message()
  end

  defp build_proposal_line(
         proposal,
         index
       ) do
    title =
      proposal.proposal_title
      |> safe_value("Sin título")
      |> truncate(120)

    """
    **#{index}. #{title}**
    ID: `#{proposal.proposal_id}`
    """
    |> String.trim()
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

    components =
      Keyword.get(
        opts,
        :components,
        []
      )

    data =
      %{content: String.trim(content)}
      |> maybe_components(components)
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
          "#{__MODULE__}: no se pudo responder interacción Discord: " <>
            inspect(reason)
        )

        {:error, reason}
    end
  end

  defp maybe_components(
         data,
         []
       ),
       do: data

  defp maybe_components(
         data,
         components
       ) do
    Map.put(
      data,
      :components,
      components
    )
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

  # ===========================================================================
  # HELPERS
  # ===========================================================================

  defp safe_value(
         nil,
         fallback
       ),
       do: fallback

  defp safe_value(
         "",
         fallback
       ),
       do: fallback

  defp safe_value(
         value,
         _fallback
       ),
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
        max_length
      ) <>
        "\n\n_Mostrando una lista parcial._"
    end
  end
end
