defmodule AuroraGov.Projector.Repo.Migrations.CreateProjectTables do
  use Ecto.Migration

  def change do
    create table(:project_table, primary_key: false) do
      add :project_id, :string, primary_key: true
      add :ou_id, :string, null: false
      add :name, :string, null: false
      add :description, :text, null: false
      add :status, :string, null: false
      add :created_at, :utc_datetime_usec
      add :updated_at, :utc_datetime_usec
    end


    create table(:task_table, primary_key: false) do
      add :task_id, :string, primary_key: true
      add :project_id, :string, null: false
      add :name, :string, null: false
      add :description, :text, null: false
      add :goal, :text, null: true
      add :person_id, :string, null: true
      add :estimated_delivery_at, :utc_datetime_usec, null: true
                        add :deliverable_evidence, :string
      add :evaluation_review, :text, null: true
      add :evaluation_score, :integer, null: true
      add :status, :string, null: false
      add :created_at, :utc_datetime_usec
      add :updated_at, :utc_datetime_usec
    end

    create index(:project_table, [:ou_id])
    create index(:task_table, [:project_id])
    create index(:task_table, [:person_id])
  end
end
