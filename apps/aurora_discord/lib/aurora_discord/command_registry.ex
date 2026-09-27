defmodule AuroraDiscord.CommandRegistry do
  @moduledoc """
  Registra los Application Commands utilizados por Aurora Discord.

  Durante desarrollo los comandos se registran específicamente
  en el guild configurado para que estén disponibles inmediatamente.
  """

  require Logger

  alias Nostrum.Api.ApplicationCommand

  @commands [
    %{
      name: "propuestas",
      description: "Muestra las propuestas de la unidad asociada a este canal"
    }
  ]

  @doc """
  Sincroniza el catálogo de comandos del bot con Discord.

  Se utiliza bulk overwrite para que el registro sea idempotente:
  reiniciar Aurora no genera comandos duplicados.
  """
  def sync_guild_commands do
    with {:ok, application_id} <-
           configured_snowflake(:application_id),
         {:ok, guild_id} <-
           configured_snowflake(:guild_id) do
      case ApplicationCommand.bulk_overwrite_guild_commands(
             application_id,
             guild_id,
             @commands
           ) do
        {:ok, commands} ->
          Logger.info(
            "#{__MODULE__}: #{length(commands)} comando(s) Discord sincronizado(s)"
          )

          {:ok, commands}

        {:error, reason} ->
          Logger.warning(
            "#{__MODULE__}: no se pudieron sincronizar los comandos: " <>
              inspect(reason)
          )

          {:error, reason}
      end
    else
      {:error, reason} ->
        Logger.warning(
          "#{__MODULE__}: configuración inválida para slash commands: " <>
            inspect(reason)
        )

        {:error, reason}
    end
  end

  # ===========================================================================
  # CONFIGURATION
  # ===========================================================================

  defp configured_snowflake(key) do
    case Application.get_env(
           :aurora_discord,
           key
         ) do
      nil ->
        {:error, {:missing_configuration, key}}

      "" ->
        {:error, {:missing_configuration, key}}

      value ->
        parse_snowflake(value)
    end
  end

  defp parse_snowflake(value)
       when is_integer(value) do
    {:ok, value}
  end

  defp parse_snowflake(value)
       when is_binary(value) do
    case Integer.parse(value) do
      {id, ""} ->
        {:ok, id}

      _ ->
        {:error, :invalid_snowflake}
    end
  end

  defp parse_snowflake(_),
    do: {:error, :invalid_snowflake}
end
