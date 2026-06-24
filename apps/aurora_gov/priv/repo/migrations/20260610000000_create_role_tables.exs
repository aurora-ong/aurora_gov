defmodule AuroraGov.Projector.Repo.Migrations.CreateRoleTables do
  use Ecto.Migration

  def change do
    create table(:ou_role_table, primary_key: false) do
      add :role_id, :string, primary_key: true
      add :ou_id, :string, null: false
      add :role_name, :string, null: false
      add :role_description, :text, null: false
      add :status, :string, null: false, default: "active"
      add :created_at, :utc_datetime_usec
      add :updated_at, :utc_datetime_usec
    end

    create table(:ou_role_assignment_table, primary_key: false) do
      add :role_id, :string, null: false, primary_key: true
      add :person_id, :string, null: false, primary_key: true
      add :ou_id, :string, null: false
      add :created_at, :utc_datetime_usec
    end

    create index(:ou_role_table, [:ou_id])
    create index(:ou_role_assignment_table, [:role_id])
    create index(:ou_role_assignment_table, [:person_id])
    create index(:ou_role_assignment_table, [:ou_id])
  end
end
