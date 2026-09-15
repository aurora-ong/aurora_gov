defmodule AuroraDiscord.EventHandler.GovernanceNotifier do
  @moduledoc """
  Event Handler encargado de transformar eventos de gobernanza de AuroraGov
  en notificaciones para Discord.

  Este módulo pertenece exclusivamente a la capa de integración.

  AuroraGov publica eventos de dominio y no conoce la existencia de Discord.
  """

  use Commanded.Event.Handler,
    application: AuroraGov,
    name: "aurora-discord-governance-notifier",
    start_from: :current

  require Logger

  alias AuroraDiscord.{
  ChannelSynchronizer,
  Client,
  Integrations
}

  alias AuroraGov.Context.{
    OUContext,
    PersonContext
  }

  alias AuroraGov.Event.{
  MembershipPromoted,
  MembershipStarted,
  OUCreated,
  OURenamed,
  ProposalCreated
}


  # ===========================================================================
  # PROPOSAL CREATED
  # ===========================================================================

  @impl true
  def handle(
        %ProposalCreated{
          proposal_id: proposal_id,
          proposal_title: proposal_title,
          proposal_owner_id: proposal_owner_id,
          proposal_ou_end_id: proposal_ou_end_id
        },
        _metadata
      ) do
    with {:ok, guild_id} <- configured_guild_id(),
         {:ok, channel_id} <-
           resolve_channel_id(
             guild_id,
             proposal_ou_end_id
           ) do
      person_name =
        resolve_person_name(
          proposal_owner_id
        )

      ou_name =
        resolve_ou_name(
          proposal_ou_end_id
        )

      message =
        build_proposal_created_message(
          person_name,
          ou_name,
          proposal_title
        )

      send_notification(
        channel_id,
        message,
        proposal_id,
        proposal_ou_end_id
      )
    else
      {:error, :missing_guild_id} ->
        Logger.warning(
          "#{__MODULE__}: DISCORD_GUILD_ID no está configurado"
        )

        :ok

      {:error, :channel_not_configured} ->
        Logger.warning(
          "#{__MODULE__}: no existe un canal Discord activo para " <>
            "la OU #{proposal_ou_end_id}"
        )

        :ok

      {:error, reason} ->
        Logger.warning(
          "#{__MODULE__}: no se pudo procesar ProposalCreated " <>
            "#{proposal_id}: #{inspect(reason)}"
        )

        :ok
    end
  end

  # ===========================================================================
# OU CREATED
# ===========================================================================

@impl true
def handle(
      %OUCreated{
        ou_id: ou_id,
        ou_name: ou_name,
        ou_goal: ou_goal,
        ou_description: ou_description
      },
      _metadata
    ) do
  ChannelSynchronizer.sync_ou(%{
    ou_id: ou_id,
    ou_name: ou_name,
    ou_goal: ou_goal,
    ou_description: ou_description
  })

  Logger.info(
    "#{__MODULE__}: OUCreated #{ou_id} enviada al sincronizador de Discord"
  )

  :ok
end


# ===========================================================================
# OU RENAMED
# ===========================================================================

@impl true
def handle(
      %OURenamed{
        ou_id: ou_id,
        ou_name: ou_name
      },
      _metadata
    ) do
  AuroraDiscord.ChannelSynchronizer.update_ou_metadata(%{
    ou_id: ou_id,
    ou_name: ou_name
  })

  Logger.info(
    "#{__MODULE__}: OURenamed #{ou_id} enviada al sincronizador de Discord"
  )

  :ok
end

# ===========================================================================
# MEMBERSHIP STARTED
# ===========================================================================

@impl true
def handle(
      %MembershipStarted{
        ou_id: ou_id,
        person_id: person_id
      },
      _metadata
    ) do
  with {:ok, guild_id} <- configured_guild_id(),
       {:ok, channel_id} <- resolve_channel_id(guild_id, ou_id) do
    person_name =
      resolve_person_name(person_id)

    ou_name =
      resolve_ou_name(ou_id)

    message =
      build_membership_started_message(
        person_name,
        ou_name
      )

    case Client.send_message(channel_id, message) do
      {:ok, _message} ->
        Logger.info(
          "#{__MODULE__}: MembershipStarted de #{person_id} " <>
            "notificado para OU #{ou_id}"
        )

        :ok

      {:error, reason} ->
        Logger.warning(
          "#{__MODULE__}: no se pudo notificar MembershipStarted " <>
            "para #{person_id}: #{inspect(reason)}"
        )

        :ok
    end
  else
    {:error, :channel_not_configured} ->
      Logger.warning(
        "#{__MODULE__}: no existe canal Discord para OU #{ou_id}"
      )

      :ok

    {:error, reason} ->
      Logger.warning(
        "#{__MODULE__}: no se pudo procesar MembershipStarted " <>
          "para #{person_id}: #{inspect(reason)}"
      )

      :ok
  end
end


# ===========================================================================
# MEMBERSHIP PROMOTED
# ===========================================================================

@impl true
def handle(
      %MembershipPromoted{
        ou_id: ou_id,
        person_id: person_id,
        membership_rank: membership_rank
      },
      _metadata
    ) do
  with {:ok, guild_id} <- configured_guild_id(),
       {:ok, channel_id} <- resolve_channel_id(guild_id, ou_id) do
    person_name =
      resolve_person_name(person_id)

    ou_name =
      resolve_ou_name(ou_id)

    message =
      build_membership_promoted_message(
        person_name,
        ou_name,
        membership_rank
      )

    case Client.send_message(channel_id, message) do
      {:ok, _message} ->
        Logger.info(
          "#{__MODULE__}: MembershipPromoted de #{person_id} " <>
            "notificado para OU #{ou_id}"
        )

        :ok

      {:error, reason} ->
        Logger.warning(
          "#{__MODULE__}: no se pudo notificar MembershipPromoted " <>
            "para #{person_id}: #{inspect(reason)}"
        )

        :ok
    end
  else
    {:error, :channel_not_configured} ->
      Logger.warning(
        "#{__MODULE__}: no existe canal Discord para OU #{ou_id}"
      )

      :ok

    {:error, reason} ->
      Logger.warning(
        "#{__MODULE__}: no se pudo procesar MembershipPromoted " <>
          "para #{person_id}: #{inspect(reason)}"
      )

      :ok
  end
end
  # ===========================================================================
  # OTHER EVENTS
  # ===========================================================================

  @impl true
  def handle(_event, _metadata), do: :ok

  # ===========================================================================
  # CHANNEL RESOLUTION
  # ===========================================================================

  defp resolve_channel_id(
         guild_id,
         ou_id
       ) do
    case Integrations.get_enabled_channel_id(
           guild_id,
           ou_id
         ) do
      nil ->
        {:error, :channel_not_configured}

      channel_id ->
        parse_snowflake(channel_id)
    end
  end

  # ===========================================================================
  # DOMAIN DATA RESOLUTION
  # ===========================================================================

  defp resolve_person_name(person_id) do
    case PersonContext.get_person!(person_id) do
      %{person_name: person_name}
      when is_binary(person_name) and person_name != "" ->
        person_name

      _ ->
        person_id
    end
  rescue
    Ecto.NoResultsError ->
      person_id
  end

  defp resolve_ou_name(ou_id) do
    case OUContext.get_ou(ou_id) do
      %{ou_name: ou_name}
      when is_binary(ou_name) and ou_name != "" ->
        ou_name

      _ ->
        ou_id
    end
  end

  # ===========================================================================
  # DISCORD DELIVERY
  # ===========================================================================



  defp send_notification(
         channel_id,
         message,
         proposal_id,
         ou_id
       ) do
    case Client.send_message(
           channel_id,
           message
         ) do
      {:ok, _discord_message} ->
        Logger.info(
          "#{__MODULE__}: ProposalCreated #{proposal_id} " <>
            "notificada en Discord para OU #{ou_id}"
        )

        :ok

      {:error, reason} ->
        Logger.warning(
          "#{__MODULE__}: no se pudo notificar ProposalCreated " <>
            "#{proposal_id}: #{inspect(reason)}"
        )

        # Discord es una integración externa.
        # Una falla de notificación no debe interrumpir AuroraGov.
        :ok
    end
  end

  # ===========================================================================
  # MESSAGE BUILDERS
  # ===========================================================================

  defp build_membership_started_message(
       person_name,
       ou_name
     ) do
  """
  👤 **Nuevo miembro**

  **#{person_name}** se incorporó a **#{ou_name}**.

  Bienvenido/a a la organización.
  """
  |> String.trim()
end


  defp build_proposal_created_message(
         person_name,
         ou_name,
         proposal_title
       ) do
    """
    📜 **Nueva propuesta**

    **#{person_name}** ha creado una nueva propuesta en **#{ou_name}**.

    **Propuesta:** #{safe_value(proposal_title)}

    🗳️ Si sos miembro de esta organización, ingresá a **la plataforma** para conocer los detalles y emitir tu voto.
    """
    |> String.trim()
  end

  defp build_membership_promoted_message(
       person_name,
       ou_name,
       membership_rank
     ) do
  rank =
    humanize_membership_rank(
      membership_rank
    )

  """
  ⬆️ **Cambio de rango**

  **#{person_name}** fue promovido/a en **#{ou_name}**.

  **Nuevo rango:** #{rank}
  """
  |> String.trim()
end

defp humanize_membership_rank(:junior),
  do: "Junior"

defp humanize_membership_rank(:regular),
  do: "Regular"

defp humanize_membership_rank(:formal),
  do: "Formal"

defp humanize_membership_rank(:senior),
  do: "Senior"

defp humanize_membership_rank(rank)
     when is_binary(rank) do
  rank
  |> String.replace("_", " ")
  |> String.capitalize()
end

defp humanize_membership_rank(rank),
  do: inspect(rank)

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
        {:error, :invalid_channel_id}
    end
  end

  defp parse_snowflake(_),
    do: {:error, :invalid_channel_id}

  defp safe_value(nil), do: "Sin título"
  defp safe_value(""), do: "Sin título"
  defp safe_value(value), do: to_string(value)
end
