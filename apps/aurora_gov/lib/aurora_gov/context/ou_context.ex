defmodule AuroraGov.Context.OUContext do
  @moduledoc """
  The OU context.
  """

  import Ecto.Query, warn: false

  alias AuroraGov.Projector.Repo
  alias AuroraGov.Projector.Model.OU

  def list_ou() do
    Repo.all(OU)
  end

  def get_ou(id) do
    Repo.get(OU, id)
  end

  def list_ou_childs(parent_ou_id) do
    active_ous = list_ou()

    Enum.filter(active_ous, fn ou ->
      AuroraGov.Utils.OUTree.get_parent(ou.ou_id) == parent_ou_id
    end)
  end

  def get_ou_tree_with_membership(user_id) do
    query =
      from ou in AuroraGov.Projector.Model.OU,
        left_join: m in AuroraGov.Projector.Model.Membership,
        on: m.ou_id == ou.ou_id and m.person_id == ^user_id,
        select: %{
          ou_id: ou.ou_id,
          ou_name: ou.ou_name,
          ou_goal: ou.ou_goal,
          created_at: ou.created_at,
          membership_rank: m.membership_rank,
          membership_created_at: m.created_at
        }

    Repo.all(query)
  end
end
