defmodule AuroraGov.Command.StartMembership do
  use AuroraGov.Command,
    gov_power: [
      id: "org.membership.start",
      name: "Iniciar membresía",
      description: "Permite iniciar la membresía de una persona en una unidad organizacional"
    ],
    fields: [
      ou_id: [command_type: :string, label: "Unidad", form_type: :text, field_type: :user],
      person_id: [
        command_type: :string,
        label: "Persona",
        description: "Identificador de la persona que iniciará su membresía",
        form_type: :text,
        field_type: :user
      ]
    ]

  def handle_validate(changeset) do
    changeset
    |> validate_required([:ou_id, :person_id])
  end
end
