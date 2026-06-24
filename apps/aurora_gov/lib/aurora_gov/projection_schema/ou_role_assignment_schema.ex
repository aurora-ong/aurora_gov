defmodule AuroraGov.Projector.Model.OURoleAssignment do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "ou_role_assignment_table" do
    field :role_id, :string, primary_key: true
    field :person_id, :string, primary_key: true
    field :ou_id, :string
    field :created_at, :utc_datetime_usec

    belongs_to :person, AuroraGov.Projector.Model.Person,
      foreign_key: :person_id,
      type: :string,
      references: :person_id,
      define_field: false
  end

  def changeset(assignment, attrs) do
    assignment
    |> cast(attrs, [:role_id, :person_id, :ou_id, :created_at])
  end
end
