defmodule AuroraGov.Projector.Repo.Migrations.AddOuAvatarUrl do
  use Ecto.Migration

  def change do
    alter table(:ou_table) do
      add :ou_avatar_url, :string
      add :ou_avatar_hash, :string
    end
  end
end
