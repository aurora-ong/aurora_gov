defmodule AuroraGov.Command.AssignRole do
  use AuroraGov.Command,
    gov_power: [
      id: "org.role.assign",
      name: "Asignar rol",
      description: "Permite asignar un rol a un miembro de la unidad organizacional",
      category: :role
    ],
    fields: [
      ou_id: [
        command_type: :string,
        label: "Unidad",
        form_type: :text,
        source: {:context, :end_ou_id}
      ],
      role_id: [
        command_type: :string,
        label: "ID del rol",
        form_type: :text,
        source: :user
      ],
      person_id: [
        command_type: :string,
        label: "Persona",
        form_type: :text,
        source: :user
      ]
    ]

  def handle_validate(changeset) do
    changeset
    |> validate_required([:ou_id, :role_id, :person_id])
  end
end
