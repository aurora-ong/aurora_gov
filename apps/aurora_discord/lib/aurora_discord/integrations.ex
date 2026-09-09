defmodule AuroraDiscord.Integrations do
  @moduledoc """
  Contexto de persistencia para las integraciones entre Aurora y Discord.

  Este módulo administra asociaciones técnicas entre las OUs del dominio
  y los canales de Discord.

  No contiene reglas de gobernanza.
  """

  import Ecto.Query, warn: false

  alias AuroraDiscord.Repo

  alias AuroraDiscord.Integrations.DiscordChannelBinding

  @doc """
  Retorna todos los bindings correspondientes a un servidor Discord.
  """
  def list_channel_bindings(guild_id) when is_binary(guild_id) do
    DiscordChannelBinding
    |> where([binding], binding.guild_id == ^guild_id)
    |> Repo.all()
  end

  @doc """
  Obtiene el binding de una OU dentro de un servidor Discord.
  """
  def get_channel_binding(guild_id, ou_id)
      when is_binary(guild_id) and is_binary(ou_id) do
    Repo.get_by(
      DiscordChannelBinding,
      guild_id: guild_id,
      ou_id: ou_id
    )
  end

  @doc """
  Crea una nueva asociación OU ↔ canal Discord.
  """
  def create_channel_binding(attrs) do
    %DiscordChannelBinding{}
    |> DiscordChannelBinding.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Actualiza un binding existente.

  Se utiliza, por ejemplo, cuando el canal asociado fue eliminado
  externamente y el sincronizador tuvo que recrearlo.
  """
  def update_channel_binding(
        %DiscordChannelBinding{} = binding,
        attrs
      ) do
    binding
    |> DiscordChannelBinding.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Obtiene el ID del canal activo correspondiente a una OU.
  """
  def get_enabled_channel_id(guild_id, ou_id)
      when is_binary(guild_id) and is_binary(ou_id) do
    DiscordChannelBinding
    |> where(
      [binding],
      binding.guild_id == ^guild_id and
        binding.ou_id == ^ou_id and
        binding.enabled == true
    )
    |> select([binding], binding.channel_id)
    |> Repo.one()
  end
end
