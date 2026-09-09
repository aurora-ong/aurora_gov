defmodule AuroraDiscord.Consumer do
  @moduledoc """
  Consumidor de eventos provenientes de Discord.

  Este módulo pertenece exclusivamente a la integración con Discord.
  No contiene reglas del dominio de gobernanza de Aurora.
  """

  use Nostrum.Consumer

  require Logger

  @impl true
  def handle_event({:READY, ready, _ws_state}) do
    Logger.info(
      "Discord bot conectado como #{ready.user.username} " <>
        "(#{ready.user.id})"
    )

    :ok
  end

  def handle_event(_event), do: :ok
end
