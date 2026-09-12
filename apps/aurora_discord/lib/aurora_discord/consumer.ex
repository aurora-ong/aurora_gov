defmodule AuroraDiscord.Consumer do
  @moduledoc """
  Consumidor de eventos provenientes de Discord.

  Este módulo pertenece exclusivamente a la integración con Discord.
  No contiene reglas del dominio de gobernanza de Aurora.
  """

  use Nostrum.Consumer

  require Logger

  alias AuroraDiscord.CommandRegistry

  alias AuroraDiscord.Commands.{
  Proposal,
  Proposals
}

alias Nostrum.Struct.Interaction,
  as: DiscordInteraction


@impl true
def handle_event(
      {
        :INTERACTION_CREATE,
        %DiscordInteraction{
          type: 3,
          data: %{
            custom_id: <<"proposal_detail:", proposal_id::binary>>
          }
        } = interaction,
        _ws_state
      }
    )
    when proposal_id != "" do
  Proposal.handle_button(
    interaction,
    proposal_id
  )
end

 @impl true
def handle_event({:READY, ready, _ws_state}) do
  Logger.info(
    "Discord bot conectado como #{ready.user.username} " <>
      "(#{ready.user.id})"
  )

  AuroraDiscord.ChannelSynchronizer.sync()

  CommandRegistry.sync_guild_commands()

  :ok
end

@impl true
def handle_event(
      {
        :INTERACTION_CREATE,
        %DiscordInteraction{
          data: %{name: "propuestas"}
        } = interaction,
        _ws_state
      }
    ) do
  Proposals.handle(interaction)
end

  def handle_event(_event), do: :ok
end
