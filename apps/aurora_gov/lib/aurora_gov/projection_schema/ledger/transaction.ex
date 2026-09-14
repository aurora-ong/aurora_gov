defmodule AuroraGov.Projector.Model.Transaction do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:transaction_id, :binary_id, autogenerate: false}
  schema "transactions" do
    field :reference_id, :string
    field :reference_type, :string
    field :timestamp, :utc_datetime

    has_many :entries, AuroraGov.Projector.Model.Entry, foreign_key: :transaction_id, references: :transaction_id

    timestamps()
  end

  def changeset(transaction, attrs) do
    transaction
    |> cast(attrs, [:transaction_id, :reference_id, :reference_type, :timestamp])
    |> validate_required([:transaction_id, :reference_type, :timestamp])
  end
end
