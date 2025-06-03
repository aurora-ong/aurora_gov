defmodule AuroraGov.Command.StartMembership do
  use AuroraGov.Command,
    ou_id: [
      type: :string,
      visible?: false
    ],
    person_id: [
      type: :string,
      label: "Persona que se unirá",
      form_type: :text,
      description: "ID de la persona que se unirá",
      visible?: true
    ]

  def handle_validate(changeset) do
    changeset
    |> validate_required([:ou_id, :person_id])
  end
end
