defmodule AuroraGov.Command.UnassignRole do
  use AuroraGov.Command,
    gov_power: [
      id: "org.role.unassign",
      name: "Desasignar rol",
      description: "Permite quitar un rol a un miembro de la unidad organizacional",
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
        form_type: :role_search,
        source: :user
      ],
      person_id: [
        command_type: :string,
        label: "Persona",
        form_type: :user_search,
        source: :user
      ]
    ]

  def handle_validate(changeset) do
    changeset
    |> validate_required([:ou_id, :role_id, :person_id])
  end
end
