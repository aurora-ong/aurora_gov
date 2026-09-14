defmodule AuroraGov.Projector.Model.Ledger do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:ledger_id, :string, autogenerate: false}
  schema "ledgers" do
    field :owner_id, :string
    field :owner_type, Ecto.Enum, values: [:ou, :project, :person, :external]
    field :ledger_type, Ecto.Enum, values: [:asset, :liability, :equity, :external]
    field :name, :string
    field :description, :string
    field :balance, :decimal
    belongs_to :resource, AuroraGov.Projector.Model.Resource, type: :string

    timestamps()
  end

  def changeset(ledger, attrs) do
    ledger
    |> cast(attrs, [:ledger_id, :owner_id, :owner_type, :ledger_type, :balance, :resource_id, :name, :description])
    |> validate_required([:ledger_id, :owner_id, :owner_type, :ledger_type, :resource_id, :name])
  end
end
