defmodule AuroraGov.Projector.Repo.Migrations.CreateProposalTable do
  use Ecto.Migration

  def change do
    create table(:proposal_table, primary_key: false) do
      add :proposal_id, :string, primary_key: true
      add :proposal_title, :string, null: false
      add :proposal_description, :string, null: false
      add :proposal_ou_start_id, :string, null: false
      add :proposal_ou_end_id, :string, null: false
      add :proposal_owner_id, :string, null: false
      add :proposal_power_id, :string, null: false
      add :proposal_power_data, :map
      add :proposal_status, :string, null: false
      add :proposal_votes, :map
      add :proposal_power_sensibility, :map
      add :proposal_execution_result, :string
      add :proposal_execution_error, :string
      add :created_at, :utc_datetime_usec
      add :updated_at, :utc_datetime_usec
      add :consumed_at, :utc_datetime_usec
    end

    create index(:proposal_table, [:proposal_ou_start_id])
    create index(:proposal_table, [:proposal_ou_end_id])
    create index(:proposal_table, [:proposal_owner_id])
  end
end
