defmodule AuroraGov.Command.RegisterPerson do
  use Commanded.Command,
    person_id: :string,
    person_name: :string,
    person_mail: :string

  def handle_validate(changeset) do
    changeset
    |> put_change(:person_id, Ecto.ShortUUID.generate())
    |> validate_required([:person_name, :person_mail])
    |> validate_format(:person_mail, ~r/@/)
  end
end
