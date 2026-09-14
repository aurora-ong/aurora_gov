defmodule AuroraGov.Context.ProjectContext do
  @moduledoc """
  The read-side context for Projects, Products, Tasks, and Efforts.
  """

  import Ecto.Query, warn: false

  alias AuroraGov.Projector.Repo
  alias AuroraGov.Projector.Model.{Project, Task}

  # --- Projects ---

  def list_projects(ou_id) do
    Project
    |> where([p], p.ou_id == ^ou_id and p.status != :archived)
    |> order_by([p], desc: p.created_at)
    |> Repo.all()
    |> Repo.preload(:tasks)
  end

  def get_project(project_id) do
    Repo.get(Project, project_id)
  end

  # --- Tasks ---

  def list_project_tasks(project_id) do
    Task
    |> where([t], t.project_id == ^project_id)
    |> order_by([t], asc: t.created_at)
    |> Repo.all()
  end

  def get_task(task_id) do
    Repo.get(Task, task_id)
  end



  def count_active_tasks_by_ou(ou_id) do
    Task
    |> join(:inner, [t], p in Project, on: t.project_id == p.project_id)
    |> where([t, p], p.ou_id == ^ou_id and t.status == :in_progress)
    |> Repo.aggregate(:count)
  end
end
