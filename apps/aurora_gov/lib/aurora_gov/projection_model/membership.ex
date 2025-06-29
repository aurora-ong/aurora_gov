defmodule AuroraGov.Projector.Model.Membership do
  use Ecto.Schema

  @primary_key {:membership_id, :string, autogenerate: false}
  schema "membership_table" do
    belongs_to :ou, AuroraGov.Projector.Model.OU,
      type: :string,
      primary_key: true,
      references: :ou_id

    belongs_to :person, AuroraGov.Projector.Model.Person,
      type: :string,
      primary_key: true,
      references: :person_id

    field :membership_status, :string
    field :created_at, :utc_datetime_usec
    field :updated_at, :utc_datetime_usec
  end
end

defimpl Phoenix.Param, for: AuroraGov.Projector.Model.Membership do
  def to_param(%{membership_id: id}), do: id
end
