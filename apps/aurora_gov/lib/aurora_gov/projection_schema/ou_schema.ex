defmodule AuroraGov.Projector.Model.OU do
  use Ecto.Schema

  @primary_key {:ou_id, :string, autogenerate: false}
  schema "ou_table" do
    field :ou_name, :string
    field :ou_goal, :string
    field :ou_description, :string
    field :ou_status, Ecto.Enum, values: [:active]
    field :created_at, :utc_datetime_usec
    field :updated_at, :utc_datetime_usec
  end
end
