defmodule AuroraGov.Projector.Repo.Migrations.CreatePowerTable do
  use Ecto.Migration

  def change do
    create table(:power_table, primary_key: false) do
      add :ou_id, :string, primary_key: true
      add :power_id, :string, primary_key: true
      add :person_id, :string, primary_key: true
      add :power_value, :integer, null: false
      add :created_at, :utc_datetime_usec
      add :updated_at, :utc_datetime_usec
    end

    create index(:power_table, [:ou_id])
    create index(:power_table, [:person_id])
    create index(:power_table, [:power_id])

    create table(:ou_power_table, primary_key: false) do
      add :ou_id, :string, primary_key: true
      add :power_id, :string, primary_key: true
      add :power_average, :decimal, precision: 5, scale: 2, null: false
      add :power_count, :integer, null: false
    end

    create index(:ou_power_table, [:ou_id])
    create index(:ou_power_table, [:power_id])
  end
end
