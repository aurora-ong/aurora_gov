defmodule AuroraGov.Projector.OURoleProjector do
  import Ecto.Query
  alias AuroraGov.Projector.Model.{OURole, OURoleAssignment}
  alias AuroraGov.Event.{OURoleCreated, OURoleAssigned, OURoleUnassigned, OURoleArchived}

  def project(%OURoleCreated{} = event, metadata, multi) do
    params = %{
      role_id: event.role_id,
      ou_id: event.ou_id,
      role_name: event.role_name,
      role_description: event.role_description,
      status: "active",
      created_at: metadata.created_at,
      updated_at: metadata.created_at
    }

    changeset = OURole.changeset(%OURole{}, params)

    multi
    |> Ecto.Multi.insert(:ou_role_insert, changeset)
    |> Ecto.Multi.run(:projector_update, fn _repo, %{ou_role_insert: role} ->
      {:ok, {:role_created, role}}
    end)
  end

  def project(%OURoleAssigned{} = event, metadata, multi) do
    params = %{
      role_id: event.role_id,
      person_id: event.person_id,
      ou_id: event.ou_id,
      created_at: metadata.created_at
    }

    changeset = OURoleAssignment.changeset(%OURoleAssignment{}, params)

    multi
    |> Ecto.Multi.insert(:ou_role_assignment_insert, changeset)
    |> Ecto.Multi.run(:projector_update, fn _repo, %{ou_role_assignment_insert: assignment} ->
      {:ok, {:role_assigned, assignment}}
    end)
  end

  def project(%OURoleUnassigned{} = event, _metadata, multi) do
    query = from(a in OURoleAssignment, 
              where: a.role_id == ^event.role_id and a.person_id == ^event.person_id)

    multi
    |> Ecto.Multi.delete_all(:ou_role_assignment_delete, query)
    |> Ecto.Multi.run(:projector_update, fn _repo, _changes ->
      {:ok, {:role_unassigned, %{role_id: event.role_id, person_id: event.person_id, ou_id: event.ou_id}}}
    end)
  end

  def project(%OURoleArchived{} = event, _metadata, multi) do
    query = from(r in OURole, where: r.role_id == ^event.role_id)

    multi
    |> Ecto.Multi.update_all(:ou_role_archive, query, set: [status: "archived"])
    |> Ecto.Multi.run(:projector_update, fn _repo, _changes ->
      {:ok, {:role_archived, %{role_id: event.role_id, ou_id: event.ou_id}}}
    end)
  end
end
