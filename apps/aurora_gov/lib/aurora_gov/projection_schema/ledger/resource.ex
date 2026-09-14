defmodule AuroraGov.Projector.Model.Resource do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :string, autogenerate: false}
  schema "resources" do
    field :name, :string
    field :description, :string
    field :is_fungible, :boolean, default: true
    field :unit_of_measure, :string
    field :ou_id, :string

    timestamps()
  end

  def changeset(resource, attrs) do
    resource
    |> cast(attrs, [:id, :name, :description, :is_fungible, :unit_of_measure, :ou_id])
    |> validate_required([:id, :name, :is_fungible, :unit_of_measure])
  end
end
