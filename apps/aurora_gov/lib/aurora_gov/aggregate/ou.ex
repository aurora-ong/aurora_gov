defmodule AuroraGov.Aggregate.OU do
  defstruct [:ou_id, :ou_status, :ou_membership, :ou_power, :ou_power_delegation, :ou_roles, :ou_projects]

  defmodule Membership do
  defstruct [:membership_rank]
end

  defmodule Power do
    defstruct [:membership_id, :power_id, :power_value, :power_updated_at]
  end

  defmodule Role do
    defstruct [:role_id, :role_name, :role_description, :status, assignments: MapSet.new()]
  end

  alias AuroraGov.Aggregate.OU

  alias AuroraGov.Event.{
    OUCreated,
    MembershipStarted,
    MembershipPromoted,
    MembershipDowngraded,
    MembershipRevoked,
    PowerUpdated,
    PowerDelegationActivated,
    PowerDelegationDeactivated,
    OURoleCreated,
    OURoleAssigned,
    OURoleUnassigned,
    OURoleArchived,
    OURenamed,
    OUGoalUpdated,
    ProjectCreated,
    ProjectUpdated,
    ProjectArchived,
    ProjectTransferred,
    TaskCreated,
    TaskUpdated,
    TaskAssigned,
    TaskCompleted,
    TaskAbandoned,
    TaskCancelled,
    TaskEvaluated
  }

  # State mutators

  def apply(
        _ou,
        %OUCreated{
          ou_id: ou_id
        }
      ) do
    %OU{
      ou_id: ou_id,
      ou_status: :active,
      ou_membership: %{},
      ou_power: %{},
      ou_power_delegation: %{},
      ou_roles: %{},
      ou_projects: %{}
    }
  end

  def apply(%OU{} = ou, %MembershipStarted{person_id: person_id}) do
    %OU{
      ou
      | ou_membership:
          Map.put(ou.ou_membership, person_id, %Membership{
            membership_rank: "junior"})
    }
  end

  def apply(
        %OU{} = ou,
        %MembershipPromoted{
          person_id: person_id,
          membership_rank: membership_rank
        }
      ) do
    %OU{
      ou
      | ou_membership:
          Map.update!(ou.ou_membership, person_id, fn membership ->
            %Membership{
              membership
              | membership_rank: membership_rank
            }
          end)
    }
  end

  def apply(
      %OU{} = ou,
      %MembershipDowngraded{
        person_id: person_id,
        membership_rank: membership_rank
      }
    ) do
  %OU{
    ou
    | ou_membership:
        Map.update!(
          ou.ou_membership,
          person_id,
          fn %Membership{} = membership ->
            %Membership{
              membership
              | membership_rank: membership_rank
            }
          end
        )
  }
end

  def apply(%OU{} = ou, %PowerUpdated{
        person_id: person_id,
        power_id: power_id,
        power_value: power_value,
        power_updated_at: power_updated_at
      }) do
    updated_power_map =
      Map.update(
        ou.ou_power || %{},
        power_id,
        %{
          person_id => %Power{
            power_id: power_id,
            power_value: power_value,
            power_updated_at: power_updated_at
          }
        },
        fn power_map ->
          Map.update(
            power_map,
            person_id,
            %Power{
              power_id: power_id,
              power_value: power_value,
              power_updated_at: power_updated_at
            },
            fn power ->
              %Power{
                power
                | power_value: power_value,
                  power_updated_at: power_updated_at
              }
            end
          )
        end
      )

    %OU{ou | ou_power: updated_power_map}
  end

  def apply(
        %OU{} = ou,
        %MembershipRevoked{
          person_id: person_id
        }
      ) do
    updated_power =
        Enum.reduce(ou.ou_power || %{}, %{}, fn {power_id, person_map}, acc ->
          Map.put(acc, power_id, Map.delete(person_map, person_id))
        end)

      %OU{
        ou
        | ou_membership: Map.delete(ou.ou_membership, person_id),
          ou_power: updated_power
      }
    end

  def apply(%OU{} = ou, %PowerDelegationActivated{
        person_id: person_id,
        power_id: power_id
      }) do
    updated_power_delegation_map =
      Map.update(
        ou.ou_power_delegation || %{},
        power_id,
        MapSet.new([person_id]),
        &MapSet.put(&1, person_id)
      )

    %OU{ou | ou_power_delegation: updated_power_delegation_map}
  end

  def apply(%OU{} = ou, %PowerDelegationDeactivated{
        person_id: person_id,
        power_id: power_id
      }) do
    updated_power_delegation_map =
      Map.update(
        ou.ou_power_delegation || %{},
        power_id,
        MapSet.new(),
        &MapSet.delete(&1, person_id)
      )

    %OU{ou | ou_power_delegation: updated_power_delegation_map}
  end

  def apply(%OU{} = ou, %OURoleCreated{
        role_id: role_id,
        role_name: role_name,
        role_description: role_description
      }) do
    new_role = %Role{
      role_id: role_id,
      role_name: role_name,
      role_description: role_description,
      status: :active,
      assignments: MapSet.new()
    }

    %OU{ou | ou_roles: Map.put(ou.ou_roles || %{}, role_id, new_role)}
  end

  def apply(%OU{} = ou, %OURoleAssigned{role_id: role_id, person_id: person_id}) do
    updated_roles =
      Map.update!(ou.ou_roles, role_id, fn role ->
        %Role{role | assignments: MapSet.put(role.assignments, person_id)}
      end)

    %OU{ou | ou_roles: updated_roles}
  end

  def apply(%OU{} = ou, %OURoleUnassigned{role_id: role_id, person_id: person_id}) do
    updated_roles =
      Map.update!(ou.ou_roles, role_id, fn role ->
        %Role{role | assignments: MapSet.delete(role.assignments, person_id)}
      end)

    %OU{ou | ou_roles: updated_roles}
  end

  def apply(%OU{} = ou, %OURoleArchived{role_id: role_id}) do
    updated_roles =
      Map.update!(ou.ou_roles, role_id, fn role ->
        %Role{role | status: :archived}
      end)

    %OU{ou | ou_roles: updated_roles}
  end

  def apply(%OU{} = ou, %ProjectCreated{} = event) do
    ou_projects = ou.ou_projects || %{}
    new_project = %{
      project_id: event.project_id,
      name: event.name,
      description: event.description,
      status: :active,
      tasks: %{}
    }
    %OU{ou | ou_projects: Map.put(ou_projects, event.project_id, new_project)}
  end

  def apply(%OU{} = ou, %ProjectUpdated{} = event) do
    ou_projects = ou.ou_projects || %{}
    updated_projects = Map.update!(ou_projects, event.project_id, fn p ->
      p
      |> Map.put(:name, event.name)
      |> Map.put(:description, event.description)
    end)
    %OU{ou | ou_projects: updated_projects}
  end

  def apply(%OU{} = ou, %ProjectArchived{} = event) do
    ou_projects = ou.ou_projects || %{}
    updated_projects = Map.update!(ou_projects, event.project_id, fn p ->
      Map.put(p, :status, :archived)
    end)
    %OU{ou | ou_projects: updated_projects}
  end

  def apply(%OU{} = ou, %ProjectTransferred{} = event) do
    ou_projects = ou.ou_projects || %{}
    %OU{ou | ou_projects: Map.delete(ou_projects, event.project_id)}
  end

  def apply(%OU{} = ou, %TaskCreated{} = event) do
    ou_projects = ou.ou_projects || %{}
    updated_projects = Map.update!(ou_projects, event.project_id, fn p ->
      tasks = p.tasks || %{}
      new_task = %{
        task_id: event.task_id,
        name: event.name,
        description: event.description,
        goal: event.goal,
        deliverable_evidence: nil,
        person_id: nil,
        estimated_delivery_at: nil,
        status: :backlog
      }
      Map.put(p, :tasks, Map.put(tasks, event.task_id, new_task))
    end)
    %OU{ou | ou_projects: updated_projects}
  end

  def apply(%OU{} = ou, %TaskUpdated{} = event) do
    ou_projects = ou.ou_projects || %{}
    updated_projects = Map.update!(ou_projects, event.project_id, fn p ->
      tasks = p.tasks || %{}
      updated_tasks = Map.update!(tasks, event.task_id, fn t ->
        t
        |> Map.put(:name, event.name)
        |> Map.put(:description, event.description)
        |> Map.put(:goal, event.goal)
      end)
      Map.put(p, :tasks, updated_tasks)
    end)
    %OU{ou | ou_projects: updated_projects}
  end

  def apply(%OU{} = ou, %TaskAssigned{} = event) do
    ou_projects = ou.ou_projects || %{}
    updated_projects = Map.update!(ou_projects, event.project_id, fn p ->
      tasks = p.tasks || %{}
      updated_tasks = Map.update!(tasks, event.task_id, fn t ->
        t
        |> Map.put(:person_id, event.person_id)
        |> Map.put(:estimated_delivery_at, event.estimated_delivery_at)
        |> Map.put(:status, :in_progress)
      end)
      Map.put(p, :tasks, updated_tasks)
    end)
    %OU{ou | ou_projects: updated_projects}
  end

  def apply(%OU{} = ou, %TaskCompleted{} = event) do
    ou_projects = ou.ou_projects || %{}
    updated_projects = Map.update!(ou_projects, event.project_id, fn p ->
      tasks = p.tasks || %{}
      updated_tasks = Map.update!(tasks, event.task_id, fn t ->
        Map.put(t, :status, :completed)
      end)
      Map.put(p, :tasks, updated_tasks)
    end)
    %OU{ou | ou_projects: updated_projects}
  end

  def apply(%OU{} = ou, %TaskAbandoned{} = event) do
    ou_projects = ou.ou_projects || %{}
    updated_projects = Map.update!(ou_projects, event.project_id, fn p ->
      tasks = p.tasks || %{}
      updated_tasks = Map.update!(tasks, event.task_id, fn t ->
        t
        |> Map.put(:person_id, nil)
        |> Map.put(:estimated_delivery_at, nil)
        |> Map.put(:status, :backlog)
      end)
      Map.put(p, :tasks, updated_tasks)
    end)
    %OU{ou | ou_projects: updated_projects}
  end

  def apply(%OU{} = ou, %TaskCancelled{} = event) do
    ou_projects = ou.ou_projects || %{}
    updated_projects = Map.update!(ou_projects, event.project_id, fn p ->
      tasks = p.tasks || %{}
      updated_tasks = Map.update!(tasks, event.task_id, fn t ->
        Map.put(t, :status, :cancelled)
      end)
      Map.put(p, :tasks, updated_tasks)
    end)
    %OU{ou | ou_projects: updated_projects}
  end

  def apply(%OU{} = ou, %TaskEvaluated{} = event) do
    ou_projects = ou.ou_projects || %{}
    updated_projects = Map.update!(ou_projects, event.project_id, fn p ->
      tasks = p.tasks || %{}
      updated_tasks = Map.update!(tasks, event.task_id, fn t ->
        t
        |> Map.put(:evaluation_review, event.review)
        |> Map.put(:evaluation_score, event.score)
      end)
      Map.put(p, :tasks, updated_tasks)
    end)
    %OU{ou | ou_projects: updated_projects}
  end


  # Functions
  def get_ou(ou_id) when is_nil(ou_id), do: {:error, :ou_not_exists}

  def get_ou(ou_id) do
    case AuroraGov.aggregate_state(OU, ou_id) do
      %OU{ou_id: nil} -> {:error, :ou_not_exists}
      %OU{} = ou -> {:ou, ou}
    end
  end

  def get_membership(%OU{ou_membership: ou_membership}, person_id) do
    case Map.fetch(ou_membership, person_id) do
      :error -> {:error, :membership_not_found}
      {:ok, %Membership{} = membership} -> {:membership, membership}
    end
  end

  def get_membership_list(%OU{ou_membership: ou_membership}) do
    ou_membership
    |> Enum.map(fn {person_id, %Membership{membership_rank: rank}} ->
      {person_id, rank}
    end)
  end

  def get_person_power(%OU{ou_power: ou_power}, power_id, person_id) do
    case get_in(ou_power, [power_id, person_id]) do
      nil -> {:error, :power_not_found}
      %Power{} = power -> {:power, power}
    end
  end

  def get_power_avg_sensitivity(%OU{ou_power: ou_power}, power_id) do
    case Map.get(ou_power, power_id) do
      nil ->
        {:ok, 0}

      power_map when map_size(power_map) == 0 ->
        {:ok, 0}

      power_map ->
        sensitivities =
          power_map
          |> Map.values()
          |> Enum.map(& &1.power_value)

        avg =
          sensitivities
          |> Enum.sum()
          |> Kernel./(length(sensitivities))

        {:ok, avg}
    end
  end

  def get_power_delegated(%OU{ou_power_delegation: power_delegation}, power_id) do
    power_delegation
    |> Map.get(power_id, MapSet.new())
    |> MapSet.to_list()
  end

  def apply(%OU{} = ou, %OURenamed{}) do
    ou
  end

  def apply(%OU{} = ou, %OUGoalUpdated{}) do
    ou
  end
end