defmodule AuroraGov.Command.ActivatePowerDelegation do
  use Commanded.Command,
    person_id: :string,
    ou_id: :string,
    power_id: :string

  def handle_validate(changeset) do
    changeset
    |> validate_required([:person_id, :ou_id, :power_id])
  end
end
