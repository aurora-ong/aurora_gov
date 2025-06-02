defmodule AuroraGov.Command.CreateOU do
  use Commanded.Command,
    ou_id: :string,
    ou_name: :string,
    ou_goal: :string,
    ou_description: :string

  def handle_validate(changeset) do
    changeset
    # |> put_change(:person_id, Ecto.ShortUUID.generate())
    |> validate_required([:ou_name, :ou_goal, :ou_description])
  end
end
