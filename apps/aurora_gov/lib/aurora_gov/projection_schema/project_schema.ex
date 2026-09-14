defmodule AuroraGov.Projector.Model.Project do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:project_id, :string, autogenerate: false}
  schema "project_table" do
    field :ou_id, :string
    field :name, :string
    field :description, :string
    field :status, Ecto.Enum, values: [:active, :archived]

    field :created_at, :utc_datetime_usec
    field :updated_at, :utc_datetime_usec

    has_many :tasks, AuroraGov.Projector.Model.Task, foreign_key: :project_id, references: :project_id
  end

  def changeset(project, attrs) do
    project
    |> cast(attrs, [:project_id, :ou_id, :name, :description, :status, :created_at, :updated_at])
    |> validate_required([:project_id, :ou_id, :name, :description, :status, :created_at, :updated_at])
  end
end
