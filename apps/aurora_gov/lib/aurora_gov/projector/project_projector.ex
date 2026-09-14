defmodule AuroraGov.Projector.ProjectProjector do
  import Ecto.Query
  alias AuroraGov.Projector.Model.{Project, Task}
  alias AuroraGov.Event.{
    ProjectCreated, ProjectUpdated, ProjectArchived, ProjectTransferred,
    TaskCreated, TaskUpdated, TaskAssigned, TaskCompleted, TaskAbandoned, TaskCancelled,
    TaskEvaluated
  }

  def project(%ProjectCreated{} = event, metadata, multi) do
    params = %{
      project_id: event.project_id,
      ou_id: event.ou_id,
      name: event.name,
      description: event.description,
      status: "active",
      created_at: metadata.created_at,
      updated_at: metadata.created_at
    }
    changeset = Project.changeset(%Project{}, params)

    multi
    |> Ecto.Multi.insert(:project_insert, changeset)
    |> Ecto.Multi.run(:projector_update, fn _repo, %{project_insert: project} ->
      {:ok, {:project_created, project}}
    end)
  end

  def project(%ProjectUpdated{} = event, metadata, multi) do
    query = from(p in Project, where: p.project_id == ^event.project_id)

    multi
    |> Ecto.Multi.update_all(:project_update, query, set: [
      name: event.name,
      description: event.description,
      updated_at: metadata.created_at
    ])
    |> Ecto.Multi.run(:projector_update, fn _repo, _changes ->
      {:ok, {:project_updated, %{project_id: event.project_id, ou_id: event.ou_id, name: event.name}}}
    end)
  end

  def project(%ProjectArchived{} = event, metadata, multi) do
    project_query = from(p in Project, where: p.project_id == ^event.project_id)
    task_query = from(t in Task, where: t.project_id == ^event.project_id)

    multi
    |> Ecto.Multi.update_all(:project_archive, project_query, set: [status: "archived", updated_at: metadata.created_at])
    |> Ecto.Multi.update_all(:tasks_archive, task_query, set: [status: "archived", updated_at: metadata.created_at])
    |> Ecto.Multi.run(:projector_update, fn _repo, _changes ->
      {:ok, {:project_archived, %{project_id: event.project_id, ou_id: event.ou_id}}}
    end)
  end

  def project(%ProjectTransferred{} = event, metadata, multi) do
    project_query = from(p in Project, where: p.project_id == ^event.project_id)

    multi
    |> Ecto.Multi.update_all(:project_transfer, project_query, set: [ou_id: event.destination_ou_id, updated_at: metadata.created_at])
    |> Ecto.Multi.run(:projector_update, fn _repo, _changes ->
      {:ok, {:project_transferred, %{project_id: event.project_id, ou_id: event.ou_id, destination_ou_id: event.destination_ou_id}}}
    end)
  end

  def project(%TaskCreated{} = event, metadata, multi) do
    params = %{
      task_id: event.task_id,
      project_id: event.project_id,
      name: event.name,
      description: event.description,
      goal: event.goal,
      status: "backlog",
      person_id: nil,
      estimated_delivery_at: nil,
      created_at: metadata.created_at,
      updated_at: metadata.created_at
    }
    changeset = Task.changeset(%Task{}, params)

    multi
    |> Ecto.Multi.insert(:task_insert, changeset)
    |> Ecto.Multi.run(:projector_update, fn _repo, %{task_insert: task} ->
      {:ok, {:task_created, task}}
    end)
  end

  def project(%TaskUpdated{} = event, metadata, multi) do
    multi
    |> Ecto.Multi.run(:task_update, fn repo, _changes ->
      task = repo.one!(from(t in Task, where: t.task_id == ^event.task_id))
      changeset = Ecto.Changeset.change(task, %{
        name: event.name,
        description: event.description,
        goal: event.goal,
        updated_at: metadata.created_at
      })
      repo.update(changeset)
    end)
    |> Ecto.Multi.run(:projector_update, fn _repo, _changes ->
      {:ok, {:task_updated, %{task_id: event.task_id, project_id: event.project_id, ou_id: event.ou_id, name: event.name}}}
    end)
  end

  def project(%TaskAssigned{} = event, metadata, multi) do
    query = from(t in Task, where: t.task_id == ^event.task_id)

    multi
    |> Ecto.Multi.update_all(:task_assign, query, set: [
      person_id: event.person_id,
      estimated_delivery_at: event.estimated_delivery_at,
      status: :in_progress,
      updated_at: metadata.created_at
    ])
    |> Ecto.Multi.run(:projector_update, fn _repo, _changes ->
      {:ok, {:task_assigned, %{task_id: event.task_id, project_id: event.project_id, ou_id: event.ou_id}}}
    end)
  end

  def project(%TaskCompleted{} = event, metadata, multi) do
    task_query = from(t in Task, where: t.task_id == ^event.task_id)

    multi
    |> Ecto.Multi.update_all(:task_status_update, task_query, set: [
      status: :completed,
      deliverable_evidence: Map.get(event, :deliverable_evidence),
      updated_at: metadata.created_at
    ])
    |> Ecto.Multi.run(:projector_update, fn _repo, _changes ->
      {:ok, {:task_completed, %{task_id: event.task_id, project_id: event.project_id, ou_id: event.ou_id}}}
    end)
  end

  def project(%TaskAbandoned{} = event, metadata, multi) do
    query = from(t in Task, where: t.task_id == ^event.task_id)

    multi
    |> Ecto.Multi.update_all(:task_abandon, query, set: [
      person_id: nil,
      estimated_delivery_at: nil,
      status: :backlog,
      updated_at: metadata.created_at
    ])
    |> Ecto.Multi.run(:projector_update, fn _repo, _changes ->
      {:ok, {:task_abandoned, %{task_id: event.task_id, project_id: event.project_id, ou_id: event.ou_id}}}
    end)
  end

  def project(%TaskCancelled{} = event, metadata, multi) do
    query = from(t in Task, where: t.task_id == ^event.task_id)

    multi
    |> Ecto.Multi.update_all(:task_cancel, query, set: [
      status: :cancelled,
      updated_at: metadata.created_at
    ])
    |> Ecto.Multi.run(:projector_update, fn _repo, _changes ->
      {:ok, {:task_cancelled, %{task_id: event.task_id, project_id: event.project_id, ou_id: event.ou_id}}}
    end)
  end

  def project(%TaskEvaluated{} = event, metadata, multi) do
    query = from(t in Task, where: t.task_id == ^event.task_id)

    multi
    |> Ecto.Multi.update_all(:task_evaluate, query, set: [
      evaluation_review: event.review,
      evaluation_score: event.score,
      updated_at: metadata.created_at
    ])
    |> Ecto.Multi.run(:projector_update, fn _repo, _changes ->
      {:ok, {:task_evaluated, %{task_id: event.task_id, project_id: event.project_id, ou_id: event.ou_id}}}
    end)
  end

end
