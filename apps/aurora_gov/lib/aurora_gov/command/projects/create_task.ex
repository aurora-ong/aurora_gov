defmodule AuroraGov.Command.CreateTask do
  use AuroraGov.Command,
    gov_power: [
      id: "org.task.create",
      name: "Crear tarea",
      description: "Permite crear una tarea asociada a un producto",
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
        source: :auto
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
    |> validate_required([:ou_id, :project_id, :name, :description, :goal])
    |> validate_length(:name, min: 3, max: 100)
    |> validate_length(:goal, min: 3, max: 255)
    |> build_task_id()
  end

  defp build_task_id(changeset) do
    case get_field(changeset, :task_id) do
      nil ->
        # Generates a 6-character alphanumeric ID (e.g., "A7B9X2")
        task_id = Enum.map(1..6, fn _ -> Enum.random(~c"0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ") end) |> to_string()
        put_change(changeset, :task_id, task_id)
      _ ->
        changeset
    end
  end
end
