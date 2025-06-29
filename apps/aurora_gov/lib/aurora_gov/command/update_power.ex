defmodule AuroraGov.Command.UpdatePower do
  use Commanded.Command,
    membership_id: :string,
    ou_id: :string,
    power_id: :string,
    power_value: :integer

  def handle_validate(changeset) do
    changeset
    |> validate_required([:person_id, :ou_id, :power_id, :power_value])
    # |> validate_number()
  end
end
