defmodule AuroraGov.Forms.SensitivityForm do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :power_value, :integer
  end

  def changeset(form, attrs) do
    form
    |> cast(attrs, [:power_value])
    |> validate_required([:power_value])
    |> validate_number(:power_value, greater_than_or_equal_to: 0, less_than_or_equal_to: 100)
  end
end
