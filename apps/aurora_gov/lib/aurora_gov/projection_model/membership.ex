defmodule AuroraGov.Projector.Model.Membership do
  use Ecto.Schema

  @primary_key {:membership_id, :string, autogenerate: false}
  schema "membership_table" do
    belongs_to :ou, AuroraGov.Projector.Model.OU, [type: :string, primary_key: true, references: :ou_id]
    belongs_to :person, AuroraGov.Projector.Model.Person, [type: :string, primary_key: true, references: :person_id]
    field :membership_status, Ecto.Enum, values: [:junior, :formal, :senior]
    field :created_at, :utc_datetime_usec
    field :updated_at, :utc_datetime_usec
  end
end
