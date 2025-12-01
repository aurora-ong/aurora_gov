defmodule AuroraGov.Command.UpdatePower do
  use Commanded.Command,
    person_id: :string,
    ou_id: :string,
    power_id: :string,
    power_value: :integer

  def handle_validate(changeset) do
    changeset
    |> validate_required([:person_id, :ou_id, :power_id, :power_value])
    |> validate_number(:power_value, greater_than_or_equal_to: 0, less_than_or_equal_to: 100)
  end
end
