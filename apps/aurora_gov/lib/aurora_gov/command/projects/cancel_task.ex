defmodule AuroraGov.Command.CancelTask do
  use AuroraGov.Command,
    gov_power: [
      id: "org.task.cancel",
      name: "Anular tarea",
      description: "Permite anular o cancelar por completo una tarea",
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
      ]
    ]

  def handle_validate(changeset, _opts) do
    changeset
    |> validate_required([:ou_id, :project_id, :task_id])
  end
end
