defmodule AuroraGov.Projector.Repo.Migrations.AddBlockChain do
  use Ecto.Migration

  def change do
    create table(:gov_blockchain, primary_key: false) do
      add :index, :bigserial, null: false, primary_key: true
      add :hash, :string, null: false
      add :prev_hash, :string, null: false

      add :event_id, :uuid, null: false
      add :event_type, :string, null: false
      add :data, :map, null: false
      add :occurred_at, :naive_datetime, null: false

      add :correlation_id, :uuid
      add :causation_id, :uuid

      add :is_visible, :boolean, default: true, null: false

      add :ou_id, :string
      add :person_id, :string
      add :proposal_id, :string
    end

    create unique_index(:gov_blockchain, [:hash])

    create index(:gov_blockchain, [:ou_id, :index])

    create index(:gov_blockchain, [:person_id, :index])

    create index(:gov_blockchain, [:proposal_id, :index])

    create index(:gov_blockchain, [:correlation_id])

    create index(:gov_blockchain, [:event_id])
  end
end
