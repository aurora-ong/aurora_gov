defmodule AuroraGov.Projector.Model.Task do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:task_id, :string, autogenerate: false}
  schema "task_table" do
    field :project_id, :string
    field :name, :string
    field :description, :string
    field :goal, :string
    field :person_id, :string
    field :estimated_delivery_at, :utc_datetime_usec
    field :status, Ecto.Enum, values: [:backlog, :in_progress, :review, :completed, :cancelled]
    field :deliverable_evidence, :string
    
    field :evaluation_review, :string
    field :evaluation_score, :integer

    field :created_at, :utc_datetime_usec
    field :updated_at, :utc_datetime_usec
  end

  def changeset(task, attrs) do
    task
    |> cast(attrs, [:task_id, :project_id, :name, :description, :goal, :person_id, :estimated_delivery_at, :status, :deliverable_evidence, :evaluation_review, :evaluation_score, :created_at, :updated_at])
    |> validate_required([:task_id, :project_id, :name, :description, :goal, :status, :created_at, :updated_at])
  end
end
