defmodule AuroraGov.Projector.Repo.Migrations.CreateMembershipTable do
  use Ecto.Migration

  def change do
    create table(:membership_table, primary_key: false) do
      add :ou_id, :string, null: false, primary_key: true
      add :person_id, :string, null: false, primary_key: true
      add :membership_status, :string, null: false
      add :created_at, :utc_datetime_usec
      add :updated_at, :utc_datetime_usec
    end

    create index(:membership_table, [:ou_id, :person_id])
  end
end
