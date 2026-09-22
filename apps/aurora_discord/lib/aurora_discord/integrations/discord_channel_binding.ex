defmodule AuroraDiscord.Integrations.DiscordChannelBinding do
  @moduledoc """
  Representa la asociación entre una unidad organizacional de Aurora
  y un canal de un servidor de Discord.

  Esta entidad pertenece exclusivamente a la capa de integración.
  No forma parte del dominio de gobernanza de AuroraGov.
  """

  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "discord_channel_bindings" do
    field :ou_id, :string

    field :guild_id, :string
    field :channel_id, :string
    field :channel_name, :string

    field :enabled, :boolean, default: true

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(binding, attrs) do
    binding
    |> cast(attrs, [
      :ou_id,
      :guild_id,
      :channel_id,
      :channel_name,
      :enabled
    ])
    |> validate_required([
      :ou_id,
      :guild_id,
      :channel_id
    ])
    |> unique_constraint(
      [:guild_id, :ou_id]
    )
    |> unique_constraint(
      [:guild_id, :channel_id]
    )
  end
end
