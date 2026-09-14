defmodule AuroraGov.Projector.Model.Entry do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:entry_id, :binary_id, autogenerate: true}
  schema "entries" do
    field :amount, :decimal
    field :description, :string
    
    belongs_to :transaction, AuroraGov.Projector.Model.Transaction, foreign_key: :transaction_id, references: :transaction_id, type: :binary_id
    belongs_to :ledger, AuroraGov.Projector.Model.Ledger, foreign_key: :ledger_id, references: :ledger_id, type: :string
    belongs_to :resource, AuroraGov.Projector.Model.Resource, type: :string

    timestamps()
  end

  def changeset(entry, attrs) do
    entry
    |> cast(attrs, [:transaction_id, :ledger_id, :resource_id, :amount, :description])
    |> validate_required([:transaction_id, :ledger_id, :resource_id, :amount])
  end
end
