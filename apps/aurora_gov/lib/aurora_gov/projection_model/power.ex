defmodule AuroraGov.Projector.Model.Power do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "power_table" do
    belongs_to :ou, AuroraGov.Projector.Model.OU,
      type: :string,
      primary_key: true,
      references: :ou_id

    field :power_id, :string, primary_key: true

    belongs_to :membership, AuroraGov.Projector.Model.Membership,
      type: :string,
      primary_key: true,
      references: :membership_id

    field :power_value, :integer
    field :created_at, :utc_datetime_usec
    field :updated_at, :utc_datetime_usec
  end

  @doc false
  def changeset(power, attrs) do
    power
    |> cast(attrs, [:ou_id, :power_id, :membership_id, :power_value, :created_at, :updated_at])
    |> validate_required([
      :ou_id,
      :power_id,
      :membership_id,
      :power_value,
      :created_at,
      :updated_at
    ])
  end
end
