defmodule AuroraGov.Projector.Repo.Migrations.CreatePowerDelegationTable do
  use Ecto.Migration

  def change do
    create table(:power_delegation_table, primary_key: false) do
      add :ou_id, :string, primary_key: true
      add :power_id, :string, primary_key: true
      add :person_id, :string, primary_key: true
      add :created_at, :utc_datetime_usec
      add :updated_at, :utc_datetime_usec
    end

    create index(:power_delegation_table, [:ou_id])
    create index(:power_delegation_table, [:person_id])
    create index(:power_delegation_table, [:power_id])
  end
end
