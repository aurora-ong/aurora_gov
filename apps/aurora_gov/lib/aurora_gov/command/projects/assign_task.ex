defmodule AuroraGov.Command.AssignTask do
  use AuroraGov.Command,
    gov_power: [
      id: "org.task.assign",
      name: "Asignar tarea",
      description: "Permite asignar una tarea a un participante y establecer una fecha estimada de entrega",
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
      person_id: [
        command_type: :string,
        label: "Participante a Asignar",
        form_type: :user_search,
        source: :user
      ],
      estimated_delivery_at: [
        command_type: :utc_datetime,
        label: "Fecha de Entrega Estimada",
        form_type: :datetime,
        source: :user
      ]
    ]

  def handle_validate(changeset, _opts) do
    changeset
    |> validate_required([:ou_id, :project_id, :task_id, :person_id, :estimated_delivery_at])
  end
end
