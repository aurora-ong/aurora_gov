defmodule AuroraGov.Projector.OU do
  @moduledoc """
  The Persons context.
  """

  import Ecto.Query, warn: false

  alias AuroraGov.Projector.Repo
  alias AuroraGov.Projector.Model.OU

  ## Database getters

  def get_all_active_ou() do
    query = from(ou in OU, where: ou.ou_status == :active, preload: [:ou, :person])
    Repo.all(query)
  end

  def get_ou_tree() do
    Repo.all(OU)
  end

  def get_ou_by_id(id) do
    Repo.get(OU, id)
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
          membership_status: m.membership_status,
          membership_created_at: m.created_at
        }

    Repo.all(query)
  end

  def get_ou_tree_with_membership() do
    query =
      from ou in AuroraGov.Projector.Model.OU,
        select: %{
          ou_id: ou.ou_id,
          ou_name: ou.ou_name,
          ou_goal: ou.ou_goal,
          membership_status: nil,
          membership_created_at: nil
        }

    Repo.all(query)
  end
end
