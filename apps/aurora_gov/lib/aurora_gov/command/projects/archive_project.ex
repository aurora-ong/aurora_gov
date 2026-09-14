defmodule AuroraGov.Command.ArchiveProject do
  use AuroraGov.Command,
    gov_power: [
      id: "org.project.archive",
      name: "Archivar proyecto",
      description: "Permite archivar un proyecto y sus tareas",
      category: :work
    ],
    fields: [
      ou_id: [
        command_type: :string,
        source: {:context, :end_ou_id}
      ],
      project_id: [
        command_type: :string,
        label: "Proyecto",
        form_type: :project_search,
        source: :user
      ]
    ]

  def handle_validate(changeset, _opts) do
    changeset
    |> validate_required([:ou_id, :project_id])
  end
end
