defmodule AuroraDiscord.Client do
  @moduledoc """
  Cliente encargado de comunicarse con la API de Discord.

  Este módulo encapsula las operaciones REST utilizadas por la integración
  y evita que otros componentes dependan directamente de Nostrum.

  Las reglas de gobernanza pertenecen a AuroraGov y no deben implementarse
  en este cliente.
  """

  require Logger

  alias Nostrum.Api.Message

  @doc """
  Envía un mensaje de texto a un canal de Discord.

  Recibe el ID del canal explícitamente para permitir que posteriormente
  cada OU pueda resolver su propio canal.
  """
  def send_message(channel_id, content)
      when is_integer(channel_id) and is_binary(content) do
    case Message.create(channel_id, content) do
      {:ok, message} ->
        {:ok, message}

      {:error, reason} ->
        Logger.warning(
          "#{__MODULE__}: no se pudo enviar mensaje a Discord " <>
            "channel_id=#{channel_id}: #{inspect(reason)}"
        )

        {:error, reason}
    end
  end
end
