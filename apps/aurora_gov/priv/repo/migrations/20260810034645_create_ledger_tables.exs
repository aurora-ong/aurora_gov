defmodule AuroraGov.Projector.Repo.Migrations.CreateLedgerTables do
  use Ecto.Migration

  def change do
    create table(:resources, primary_key: false) do
      add :id, :string, primary_key: true
      add :name, :string, null: false
      add :description, :text
      add :is_fungible, :boolean, default: true, null: false
      add :unit_of_measure, :string
      add :ou_id, :string

      timestamps()
    end

    create table(:ledgers, primary_key: false) do
      add :ledger_id, :string, primary_key: true
      add :owner_id, :string, null: false
      add :owner_type, :string, null: false
      add :ledger_type, :string, null: false, default: "asset"
      add :name, :string, null: false
      add :description, :text
      add :balance, :decimal, null: false, default: 0
      add :resource_id, references(:resources, type: :string, column: :id, on_delete: :restrict), null: false

      timestamps()
    end

    create table(:transactions, primary_key: false) do
      add :transaction_id, :uuid, primary_key: true
      add :reference_id, :string
      add :reference_type, :string
      add :timestamp, :utc_datetime, null: false

      timestamps()
    end

    create table(:entries, primary_key: false) do
      add :entry_id, :uuid, primary_key: true
      add :amount, :decimal, null: false
      add :transaction_id, references(:transactions, column: :transaction_id, type: :uuid, on_delete: :delete_all), null: false
      add :ledger_id, references(:ledgers, column: :ledger_id, type: :string, on_delete: :restrict), null: false
      add :resource_id, references(:resources, type: :string, column: :id, on_delete: :restrict), null: false
      add :description, :string

      timestamps()
    end

  end
end
