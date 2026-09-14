defmodule AuroraGov.Command.UpdateProject do
  use AuroraGov.Command,
    gov_power: [
      id: "org.project.update",
      name: "Actualizar proyecto",
      description: "Permite actualizar la información (nombre y descripción) de un proyecto",
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
      ],
      name: [
        command_type: :string,
        label: "Nuevo nombre del proyecto",
        form_type: :text,
        source: :user
      ],
      description: [
        command_type: :string,
        label: "Nueva descripción del proyecto",
        form_type: :textarea,
        source: :user
      ]
    ]

  def handle_validate(changeset, _opts) do
    changeset
    |> validate_required([:ou_id, :project_id, :name, :description])
    |> validate_length(:name, min: 3, max: 100)
    |> validate_length(:description, min: 10, max: 1000)
  end
end
