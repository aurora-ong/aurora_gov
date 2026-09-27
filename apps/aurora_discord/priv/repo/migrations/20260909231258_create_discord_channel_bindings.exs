defmodule AuroraDiscord.Repo.Migrations.CreateDiscordChannelBindings do
  use Ecto.Migration

  def change do
    create table(:discord_channel_bindings, primary_key: false) do
      add :id, :binary_id, primary_key: true

      # Identificador de la OU dentro de Aurora.
      add :ou_id, :string, null: false

      # Identificadores de Discord.
      add :guild_id, :string, null: false
      add :channel_id, :string, null: false

      # Nombre descriptivo del canal.
      add :channel_name, :string

      # Permite deshabilitar el vínculo sin eliminarlo.
      add :enabled, :boolean,
        null: false,
        default: true

      timestamps(type: :utc_datetime_usec)
    end

    # Una OU solo puede estar asociada a un canal
    # dentro de un mismo servidor Discord.
    create unique_index(
             :discord_channel_bindings,
             [:guild_id, :ou_id]
           )

    # Un canal no puede representar dos OUs
    # dentro del mismo servidor Discord.
    create unique_index(
             :discord_channel_bindings,
             [:guild_id, :channel_id]
           )

    create index(
             :discord_channel_bindings,
             [:ou_id, :enabled]
           )
  end
end
