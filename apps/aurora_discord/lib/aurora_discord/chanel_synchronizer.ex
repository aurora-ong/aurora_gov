defmodule AuroraDiscord.ChannelSynchronizer do
  @moduledoc """
  Sincroniza las unidades organizacionales existentes en Aurora
  con canales de texto dentro del servidor Discord configurado.

  La sincronización es idempotente:

  - Si una OU ya posee un canal válido, no crea otro.
  - Si no existe un binding, crea el canal y registra la asociación.
  - Si existe un binding pero el canal fue eliminado de Discord,
    recrea el canal y actualiza la asociación.

  Discord continúa siendo una integración externa.
  El dominio AuroraGov no depende de este sincronizador.
  """

  use GenServer

  require Logger

  alias AuroraDiscord.Integrations
  alias AuroraGov.Context.OUContext

  alias Nostrum.Api.Channel

  # ===========================================================================
  # CLIENT API
  # ===========================================================================

  def start_link(_opts) do
    GenServer.start_link(
      __MODULE__,
      %{},
      name: __MODULE__
    )
  end

  @doc """
  Solicita una sincronización de las OUs con Discord.
  """
  def sync do
    GenServer.cast(__MODULE__, :sync)
  end

  @doc """
Sincroniza una única OU con Discord.

Se utiliza cuando AuroraGov publica un evento `OUCreated`,
permitiendo crear el canal inmediatamente sin esperar
una nueva sincronización completa del servidor.
"""
def sync_ou(%{ou_id: ou_id} = ou)
    when is_binary(ou_id) do
  GenServer.cast(
    __MODULE__,
    {:sync_ou, ou}
  )
end

  # ===========================================================================
  # SERVER
  # ===========================================================================

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
def handle_cast(
      {:sync_ou, ou},
      state
    ) do
  with {:ok, guild_id_string} <- configured_guild_id(),
       {:ok, guild_id} <- parse_snowflake(guild_id_string) do
    Logger.info(
      "#{__MODULE__}: sincronizando nueva OU #{ou.ou_id}"
    )

    synchronize_ou(
      guild_id,
      guild_id_string,
      ou
    )
  else
    {:error, reason} ->
      Logger.warning(
        "#{__MODULE__}: no se pudo sincronizar OU #{ou.ou_id}: " <>
          inspect(reason)
      )
  end

  {:noreply, state}
end

  # ===========================================================================
  # SYNCHRONIZATION
  # ===========================================================================

  defp synchronize_channels do
    with {:ok, guild_id_string} <- configured_guild_id(),
         {:ok, guild_id} <- parse_snowflake(guild_id_string) do
      ous = OUContext.list_ou()

      Logger.info(
        "#{__MODULE__}: iniciando sincronización de #{length(ous)} OUs"
      )

      Enum.each(ous, fn ou ->
        synchronize_ou(
          guild_id,
          guild_id_string,
          ou
        )
      end)

      Logger.info(
        "#{__MODULE__}: sincronización de canales finalizada"
      )
    else
      {:error, reason} ->
        Logger.warning(
          "#{__MODULE__}: no se pudo iniciar la sincronización: " <>
            inspect(reason)
        )
    end
  end

  defp synchronize_ou(
         guild_id,
         guild_id_string,
         ou
       ) do
    case Integrations.get_channel_binding(
           guild_id_string,
           ou.ou_id
         ) do
      nil ->
        create_channel_and_binding(
          guild_id,
          guild_id_string,
          ou
        )

      binding ->
        validate_existing_binding(
          guild_id,
          guild_id_string,
          ou,
          binding
        )
    end
  end

  # ===========================================================================
  # EXISTING BINDINGS
  # ===========================================================================

  defp validate_existing_binding(
         guild_id,
         guild_id_string,
         ou,
         binding
       ) do
    with {:ok, channel_id} <-
           parse_snowflake(binding.channel_id) do
      case Channel.get(channel_id) do
        {:ok, _channel} ->
          Logger.debug(
            "#{__MODULE__}: OU #{ou.ou_id} ya está vinculada " <>
              "al canal #{binding.channel_id}"
          )

          :ok

        {:error, %Nostrum.Error.ApiError{status_code: 404}} ->
          Logger.warning(
            "#{__MODULE__}: el canal #{binding.channel_id} de la OU " <>
              "#{ou.ou_id} ya no existe; será recreado"
          )

          recreate_channel(
            guild_id,
            guild_id_string,
            ou,
            binding
          )

        {:error, reason} ->
          Logger.warning(
            "#{__MODULE__}: no se pudo verificar el canal " <>
              "#{binding.channel_id} para #{ou.ou_id}: " <>
              inspect(reason)
          )

          :error
      end
    else
      {:error, reason} ->
        Logger.warning(
          "#{__MODULE__}: channel_id inválido para #{ou.ou_id}: " <>
            inspect(reason)
        )

        :error
    end
  end

  # ===========================================================================
  # CHANNEL CREATION
  # ===========================================================================

  defp create_channel_and_binding(
         guild_id,
         guild_id_string,
         ou
       ) do
    channel_name = build_channel_name(ou.ou_id)

    case create_discord_channel(
           guild_id,
           channel_name,
           ou
         ) do
      {:ok, channel} ->
        attrs = %{
          ou_id: ou.ou_id,
          guild_id: guild_id_string,
          channel_id: Integer.to_string(channel.id),
          channel_name: channel.name,
          enabled: true
        }

        case Integrations.create_channel_binding(attrs) do
          {:ok, _binding} ->
            Logger.info(
              "#{__MODULE__}: canal ##{channel.name} creado " <>
                "para OU #{ou.ou_id}"
            )

            :ok

          {:error, changeset} ->
            Logger.error(
              "#{__MODULE__}: canal creado en Discord pero no se pudo " <>
                "guardar el binding para #{ou.ou_id}: " <>
                inspect(changeset.errors)
            )

            {:error, :binding_not_persisted}
        end

      {:error, reason} ->
        Logger.warning(
          "#{__MODULE__}: no se pudo crear canal para #{ou.ou_id}: " <>
            inspect(reason)
        )

        {:error, reason}
    end
  end

  defp recreate_channel(
         guild_id,
         _guild_id_string,
         ou,
         binding
       ) do
    channel_name = build_channel_name(ou.ou_id)

    case create_discord_channel(
           guild_id,
           channel_name,
           ou
         ) do
      {:ok, channel} ->
        case Integrations.update_channel_binding(
               binding,
               %{
                 channel_id: Integer.to_string(channel.id),
                 channel_name: channel.name,
                 enabled: true
               }
             ) do
          {:ok, _updated_binding} ->
            Logger.info(
              "#{__MODULE__}: canal ##{channel.name} recreado " <>
                "para OU #{ou.ou_id}"
            )

            :ok

          {:error, changeset} ->
            Logger.error(
              "#{__MODULE__}: no se pudo actualizar el binding de " <>
                "#{ou.ou_id}: #{inspect(changeset.errors)}"
            )

            {:error, :binding_not_updated}
        end

      {:error, reason} ->
        Logger.warning(
          "#{__MODULE__}: no se pudo recrear canal para #{ou.ou_id}: " <>
            inspect(reason)
        )

        {:error, reason}
    end
  end

  defp create_discord_channel(
         guild_id,
         channel_name,
         ou
       ) do
    topic =
      "Canal de la unidad #{safe_value(ou.ou_name)} " <>
        "(#{ou.ou_id})"

    Channel.create(
      guild_id,
      name: channel_name,
      type: 0,
      topic: String.slice(topic, 0, 1024)
    )
  end

  # ===========================================================================
  # CHANNEL NAME
  # ===========================================================================

  defp build_channel_name(ou_id) do
    base_name =
      ou_id
      |> String.downcase()
      |> String.replace(".", "-")
      |> String.replace("_", "-")

    cond do
      String.length(base_name) < 2 ->
        "ou-#{base_name}"

      String.length(base_name) <= 100 ->
        base_name

      true ->
        suffix =
          :crypto.hash(:sha256, ou_id)
          |> Base.encode16(case: :lower)
          |> String.slice(0, 6)

        "#{String.slice(base_name, 0, 90)}-#{suffix}"
    end
  end

  # ===========================================================================
  # CONFIGURATION
  # ===========================================================================

  defp configured_guild_id do
    case Application.get_env(
           :aurora_discord,
           :guild_id
         ) do
      nil ->
        {:error, :missing_guild_id}

      "" ->
        {:error, :missing_guild_id}

      guild_id ->
        {:ok, guild_id}
    end
  end

  defp parse_snowflake(value) when is_integer(value),
    do: {:ok, value}

  defp parse_snowflake(value) when is_binary(value) do
    case Integer.parse(value) do
      {id, ""} ->
        {:ok, id}

      _ ->
        {:error, :invalid_snowflake}
    end
  end

  defp parse_snowflake(_),
    do: {:error, :invalid_snowflake}

  defp safe_value(nil), do: "Sin nombre"
  defp safe_value(""), do: "Sin nombre"
  defp safe_value(value), do: to_string(value)
end
