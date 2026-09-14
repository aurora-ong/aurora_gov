defmodule AuroraGov.CommandHandler.ProjectHandler do
  @behaviour Commanded.Commands.Handler
  alias AuroraGov.Aggregate.OU
  alias AuroraGov.Command.{
    CreateProject, UpdateProject, ArchiveProject, TransferProject,
    CreateTask, UpdateTask, AssignTask, CompleteTask, AbandonTask, CancelTask,
    EvaluateTask
  }
  alias AuroraGov.Event.{
    ProjectCreated, ProjectUpdated, ProjectArchived, ProjectTransferred,
    TaskCreated, TaskUpdated, TaskAssigned, TaskCompleted, TaskAbandoned, TaskCancelled,
    TaskEvaluated
  }

  def handle(%OU{ou_id: nil}, _command) do
    {:error, :ou_not_exists}
  end

  def handle(%OU{ou_status: :archived}, _command) do
    {:error, :ou_archived}
  end

  # CreateProject
  def handle(%OU{} = ou, %CreateProject{} = cmd) do
    projects = ou.ou_projects || %{}
    if Map.has_key?(projects, cmd.project_id) do
      {:error, :project_already_exists}
    else
      %ProjectCreated{
        ou_id: cmd.ou_id,
        project_id: cmd.project_id,
        name: cmd.name,
        description: cmd.description
      }
    end
  end

  # UpdateProject
  def handle(%OU{} = ou, %UpdateProject{} = cmd) do
    projects = ou.ou_projects || %{}
    case Map.get(projects, cmd.project_id) do
      nil -> {:error, :project_not_found}
      %{status: :archived} -> {:error, :project_archived}
      _project ->
        %ProjectUpdated{
          ou_id: cmd.ou_id,
          project_id: cmd.project_id,
          name: cmd.name,
          description: cmd.description
        }
    end
  end

  # ArchiveProject
  def handle(%OU{} = ou, %ArchiveProject{} = cmd) do
    projects = ou.ou_projects || %{}
    case Map.get(projects, cmd.project_id) do
      nil -> {:error, :project_not_found}
      %{status: :archived} -> {:error, :project_already_archived}
      _project ->
        %ProjectArchived{
          ou_id: cmd.ou_id,
          project_id: cmd.project_id
        }
    end
  end

  # TransferProject
  def handle(%OU{} = ou, %TransferProject{} = cmd) do
    projects = ou.ou_projects || %{}
    case Map.get(projects, cmd.project_id) do
      nil -> {:error, :project_not_found}
      _project ->
        %ProjectTransferred{
          ou_id: cmd.ou_id,
          project_id: cmd.project_id,
          destination_ou_id: cmd.destination_ou_id
        }
    end
  end

  # CreateTask
  def handle(%OU{} = ou, %CreateTask{} = cmd) do
    projects = ou.ou_projects || %{}
    case Map.get(projects, cmd.project_id) do
      nil -> {:error, :project_not_found}
      %{status: :archived} -> {:error, :project_archived}
      project ->
        tasks = project.tasks || %{}
        if Map.has_key?(tasks, cmd.task_id) do
          {:error, :task_already_exists}
        else
          %TaskCreated{
            ou_id: cmd.ou_id,
            project_id: cmd.project_id,
            task_id: cmd.task_id,
            name: cmd.name,
            description: cmd.description,
            goal: cmd.goal
          }
        end
    end
  end

  # UpdateTask
  def handle(%OU{} = ou, %UpdateTask{} = cmd) do
    projects = ou.ou_projects || %{}
    case Map.get(projects, cmd.project_id) do
      nil -> {:error, :project_not_found}
      %{status: :archived} -> {:error, :project_archived}
      project ->
        tasks = project.tasks || %{}
        case Map.get(tasks, cmd.task_id) do
          nil -> {:error, :task_not_found}
          %{status: :archived} -> {:error, :task_archived}
          _task ->
            %TaskUpdated{
              ou_id: cmd.ou_id,
              project_id: cmd.project_id,
              task_id: cmd.task_id,
              name: cmd.name,
              description: cmd.description,
              goal: cmd.goal
            }
        end
    end
  end

  # AssignTask
  def handle(%OU{} = ou, %AssignTask{} = cmd) do
    projects = ou.ou_projects || %{}
    case Map.get(projects, cmd.project_id) do
      nil -> {:error, :project_not_found}
      %{status: :archived} -> {:error, :project_archived}
      project ->
        members = ou.ou_membership || %{}
        if not Map.has_key?(members, cmd.person_id) do
          {:error, :person_not_ou_member}
        else
          tasks = project.tasks || %{}
          case Map.get(tasks, cmd.task_id) do
            nil -> {:error, :task_not_found}
            %{status: :archived} -> {:error, :task_archived}
            %{status: :completed} -> {:error, :task_already_completed}
            _task ->
              %TaskAssigned{
                ou_id: cmd.ou_id,
                project_id: cmd.project_id,
                task_id: cmd.task_id,
                person_id: cmd.person_id,
                estimated_delivery_at: cmd.estimated_delivery_at
              }
          end
        end
    end
  end



  # CompleteTask
  def handle(%OU{} = ou, %CompleteTask{} = cmd) do
    projects = ou.ou_projects || %{}
    case Map.get(projects, cmd.project_id) do
      nil -> {:error, :project_not_found}
      %{status: :archived} -> {:error, :project_archived}
      project ->
        tasks = project.tasks || %{}
        case Map.get(tasks, cmd.task_id) do
          nil -> {:error, :task_not_found}
          %{status: :archived} -> {:error, :task_archived}
          %{status: :completed} -> {:error, :task_already_completed}
          task ->
            %TaskCompleted{
              ou_id: cmd.ou_id,
              project_id: cmd.project_id,
              task_id: cmd.task_id,
              deliverable_evidence: Map.get(task, :deliverable_evidence)
            }
        end
    end
  end



  # AbandonTask
  def handle(%OU{} = ou, %AbandonTask{} = cmd) do
    projects = ou.ou_projects || %{}
    case Map.get(projects, cmd.project_id) do
      nil -> {:error, :project_not_found}
      %{status: :archived} -> {:error, :project_archived}
      project ->
        tasks = project.tasks || %{}
        case Map.get(tasks, cmd.task_id) do
          nil -> {:error, :task_not_found}
          %{status: :archived} -> {:error, :task_archived}
          %{status: :completed} -> {:error, :task_already_completed}
          task ->
            if task.person_id == nil do
              {:error, :task_not_assigned}
            else
              %TaskAbandoned{
                ou_id: cmd.ou_id,
                project_id: cmd.project_id,
                task_id: cmd.task_id
              }
            end
        end
    end
  end

  # CancelTask
  def handle(%OU{} = ou, %CancelTask{} = cmd) do
    projects = ou.ou_projects || %{}
    case Map.get(projects, cmd.project_id) do
      nil -> {:error, :project_not_found}
      %{status: :archived} -> {:error, :project_archived}
      project ->
        tasks = project.tasks || %{}
        case Map.get(tasks, cmd.task_id) do
          nil -> {:error, :task_not_found}
          %{status: :archived} -> {:error, :task_archived}
          %{status: :completed} -> {:error, :task_already_completed}
          _task ->
            %TaskCancelled{
              ou_id: cmd.ou_id,
              project_id: cmd.project_id,
              task_id: cmd.task_id
            }
        end
    end
  end

  # EvaluateTask
  def handle(%OU{} = ou, %EvaluateTask{} = cmd) do
    projects = ou.ou_projects || %{}
    case Map.get(projects, cmd.project_id) do
      nil -> {:error, :project_not_found}
      project ->
        tasks = project.tasks || %{}
        case Map.get(tasks, cmd.task_id) do
          nil -> {:error, :task_not_found}
          %{status: status} when status != :completed -> {:error, :task_not_completed}
          _task ->
            %TaskEvaluated{
              ou_id: cmd.ou_id,
              project_id: cmd.project_id,
              task_id: cmd.task_id,
              review: cmd.review,
              score: cmd.score
            }
        end
    end
  end

end
