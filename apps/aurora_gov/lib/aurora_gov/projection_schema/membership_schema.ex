defmodule AuroraGov.Projector.Model.Membership do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {
    Flop.Schema,
    filterable: [:membership_status, :membership_rank, :person_name],
    sortable: [:created_at, :membership_rank, :membership_status, :person_name],
    default_limit: 10,
    default_order: %{order_by: [:created_at], order_directions: [:desc]},
    adapter_opts: [
      join_fields: [
        person_name: [binding: :person, field: :person_name],
        person_mail: [binding: :person, field: :person_mail]
      ]
    ]
  }

  @primary_key false
  schema "membership_table" do
    belongs_to :ou, AuroraGov.Projector.Model.OU,
      type: :string,
      primary_key: true,
      references: :ou_id

    belongs_to :person, AuroraGov.Projector.Model.Person,
      type: :string,
      primary_key: true,
      references: :person_id

    field :membership_rank, Ecto.Enum, values: [:junior, :regular, :senior]

    field :membership_status, Ecto.Enum,
      values: [:active, :suspended, :expelled, :resigned, :deceased]

    field :created_at, :utc_datetime_usec
    field :updated_at, :utc_datetime_usec
  end

  def changeset(membership, attrs) do
    membership
    |> cast(attrs, [:ou_id, :person_id, :membership_rank, :membership_status, :created_at, :updated_at])
  end
end
