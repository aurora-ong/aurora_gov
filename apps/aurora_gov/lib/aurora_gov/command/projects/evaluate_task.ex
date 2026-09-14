defmodule AuroraGov.Command.EvaluateTask do
  use AuroraGov.Command,
    gov_power: [
      id: "org.task.evaluate",
      name: "Evaluar tarea",
      description: "Permite evaluar una tarea completada, asignando una nota y un comentario",
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
      review: [
        command_type: :string,
        label: "Reseña de evaluación",
        form_type: :textarea,
        source: :user
      ],
      score: [
        command_type: :integer,
        label: "Nota / Puntaje (1-100)",
        form_type: :number,
        source: :user
      ]
    ]

  def handle_validate(changeset, _opts) do
    changeset
    |> validate_required([:ou_id, :project_id, :task_id, :review, :score])
    |> validate_number(:score, greater_than_or_equal_to: 1, less_than_or_equal_to: 100)
  end
end
