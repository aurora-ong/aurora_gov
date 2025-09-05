defmodule AuroraGov.Projector.Model.OUPower do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "ou_power_table" do
    belongs_to :ou, AuroraGov.Projector.Model.OU,
      type: :string,
      primary_key: true,
      references: :ou_id

    field :power_id, :string, primary_key: true
    field :power_average, :decimal
    field :power_count, :integer
  end

  def changeset(power, attrs) do
    power
    |> cast(attrs, [:ou_id, :power_id, :power_average, :power_count])
    |> validate_required([:ou_id, :power_id, :power_average, :power_count])
  end
end
