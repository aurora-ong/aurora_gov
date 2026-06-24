defmodule AuroraGov.Projector.Model.OURole do
  @moduledoc """
  Read model for Organizational Unit Roles.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:role_id, :string, autogenerate: false}
  @derive {
    Flop.Schema,
    filterable: [:role_name, :status],
    sortable: [:created_at, :role_name],
    default_limit: 10,
    default_order: %{order_by: [:created_at], order_directions: [:desc]}
  }
  schema "ou_role_table" do
    field :ou_id, :string
    field :role_name, :string
    field :role_description, :string
    field :status, :string, default: "active"
    field :created_at, :utc_datetime_usec
    field :updated_at, :utc_datetime_usec
  end

  def changeset(role, attrs) do
    role
    |> cast(attrs, [:role_id, :ou_id, :role_name, :role_description, :status, :created_at, :updated_at])
  end
end
