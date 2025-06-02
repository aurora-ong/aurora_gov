defmodule AuroraGov.Projector.Repo.Migrations.CreateOUTables do
  use Ecto.Migration

  def change do
    create table(:ou_table, primary_key: false) do
      add :ou_id, :citext, primary_key: true
      add :ou_name, :string, null: false
      add :ou_goal, :string, null: false
      add :ou_description, :text, null: false
      add :ou_status, :string, null: false
      add :created_at, :utc_datetime_usec
      add :updated_at, :utc_datetime_usec
    end

    create unique_index(:ou_table, [:ou_id])
  end
end
