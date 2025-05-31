defmodule AuroraGov.Projector.Repo.Migrations.CreatePersonTables do
  use Ecto.Migration

  def change do

    execute "CREATE EXTENSION IF NOT EXISTS citext", ""

    create table(:person_table, primary_key: false) do
      add :person_id, :string, primary_key: true
      add :person_name, :string, null: false
      add :person_mail, :citext, null: false
      add :person_secret, :string, null: false
      add :created_at, :utc_datetime_usec
      add :updated_at, :utc_datetime_usec
    end

    create unique_index(:person_table, [:person_id])
  end
end
