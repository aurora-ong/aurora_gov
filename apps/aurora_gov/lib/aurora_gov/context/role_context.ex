defmodule AuroraGov.Context.RoleContext do
  @moduledoc """
  The Role context.
  """
  import Ecto.Query, warn: false
  alias AuroraGov.Projector.Repo
  alias AuroraGov.Projector.Model.{OURole, OURoleAssignment}

  def list_roles_by_ou(ou_id, params \\ %{}) do
    query = OURole |> where([r], r.ou_id == ^ou_id)

    query =
      case Map.get(params, "status") do
        "all" -> query
        nil -> where(query, [r], r.status == "active")
        status -> where(query, [r], r.status == ^status)
      end

    Flop.validate_and_run(query, params, for: OURole)
  end

  def list_assignments_by_ou(ou_id) do
    OURoleAssignment
    |> where([a], a.ou_id == ^ou_id)
    |> preload([:person])
    |> Repo.all()
  end

  def list_assignments_by_role(role_id) do
    OURoleAssignment
    |> where([a], a.role_id == ^role_id)
    |> Repo.all()
  end
end
