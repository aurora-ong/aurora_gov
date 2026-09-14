defmodule AuroraGov.Command.UpdateTask do
  use AuroraGov.Command,
    gov_power: [
      id: "org.task.update",
      name: "Actualizar tarea",
      description: "Permite actualizar la información de una tarea",
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
      task_id: [
        command_type: :string,
        label: "Tarea",
        form_type: :task_search,
        source: :user
      ],
      name: [
        command_type: :string,
        label: "Nombre de la tarea",
        form_type: :text,
        source: :user
      ],
      description: [
        command_type: :string,
        label: "Descripción",
        form_type: :textarea,
        source: :user
      ],
      goal: [
        command_type: :string,
        label: "Objetivo de la tarea",
        form_type: :text,
        source: :user
      ]
    ]

  def handle_validate(changeset, _opts) do
    changeset
    |> validate_required([:ou_id, :project_id, :task_id, :name, :description, :goal])
    |> validate_length(:goal, min: 3, max: 255)
    |> validate_length(:name, min: 3, max: 100)
  end
end
