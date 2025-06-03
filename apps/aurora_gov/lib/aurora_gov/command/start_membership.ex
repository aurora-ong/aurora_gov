defmodule AuroraGov.Command.StartMembership do
  use AuroraGov.Command,
    gov_power: [
      id: "org.membership.start",
      name: "Iniciar membresía",
      description: "Permite iniciar la membresía de una persona en una unidad organizacional"
    ],
    fields: [
      ou_id: [type: :string, label: "Unidad", form_type: :text, visible?: true],
      person_id: [type: :string, label: "Persona", form_type: :text, visible?: true]
    ]

  def handle_validate(changeset) do
    changeset
    |> validate_required([:ou_id, :person_id])
  end
end
