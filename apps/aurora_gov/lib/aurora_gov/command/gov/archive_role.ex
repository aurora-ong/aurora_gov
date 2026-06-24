defmodule AuroraGov.Command.ArchiveRole do
  use AuroraGov.Command,
    gov_power: [
      id: "org.role.archive",
      name: "Archivar rol",
      description: "Permite archivar un rol de la unidad organizacional si no tiene asignaciones",
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
      ]
    ]

  def handle_validate(changeset) do
    changeset
    |> validate_required([:ou_id, :role_id])
  end
end
