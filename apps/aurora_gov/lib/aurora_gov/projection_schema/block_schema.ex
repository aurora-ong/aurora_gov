defmodule AuroraGov.Projector.Model.Block do
  use Ecto.Schema
  import Ecto.Changeset


  @derive {Flop.Schema,
    filterable: [:ou_id, :person_id, :event_type, :is_visible, :occurred_at, :hash],
    sortable: [:index, :occurred_at],
    default_limit: 20,
    max_limit: 100,
    default_order: %{
      order_by: [:index],
      order_directions: [:desc]
    }
  }

  @primary_key {:index, :integer, autogenerate: false}
  schema "gov_blockchain" do
    field :hash, :string
    field :prev_hash, :string

    field :event_id, :binary_id
    field :event_type, :string
    field :occurred_at, :utc_datetime_usec

    field :correlation_id, :binary_id
    field :causation_id, :binary_id

    field :data, :map
    field :is_visible, :boolean, default: true

    belongs_to :ou, AuroraGov.Projector.Model.OU,
      foreign_key: :ou_id,
      type: :string,
      references: :ou_id

    belongs_to :person, AuroraGov.Projector.Model.Person,
      foreign_key: :person_id,
      type: :string,
      references: :person_id
  end

  def changeset(entry, attrs) do
    entry
    |> cast(attrs, [
      :index,
      :hash,
      :prev_hash,
      :event_id,
      :event_type,
      :occurred_at,
      :correlation_id,
      :causation_id,
      :data,
      :is_visible,
      :ou_id,
      :person_id
    ])
    # Validamos lo mínimo para que exista un bloque válido
    |> validate_required([:index, :hash, :prev_hash, :event_id, :data, :ou_id])
  end
end
