defmodule AuroraGov.Context.MembershipContext do
  @moduledoc """
  The Persons context.
  """

  import Ecto.Query, warn: false

  alias AuroraGov.Projector.Repo
  alias AuroraGov.Projector.Model.Membership

  def list_memberships_by_ou(ou_id, params \\ %{}) do
    Membership
    |> where([m], m.ou_id == ^ou_id)
    |> join(:left, [m], p in assoc(m, :person), as: :person)
    |> preload([m, p], person: p)
    |> Flop.validate_and_run(params, for: Membership)
  end

  def count_active_memberships_by_ou(ou_id, rank \\ nil) do
    query =
      Membership
      |> where([m], m.ou_id == ^ou_id)
      |> where([m], m.membership_status == :active)

    query =
      case rank do
        nil -> query
        ranks when is_list(ranks) -> where(query, [m], m.membership_rank in ^ranks)
        single_rank -> where(query, [m], m.membership_rank == ^single_rank)
      end

    Repo.aggregate(query, :count, :membership_rank)
  end


  def get_membership(ou_id, person_id) do
    query = from(m in Membership, where: m.ou_id == ^ou_id and m.person_id == ^person_id)
    Repo.one(query)
  end


  def list_active_memberships_in_ou_subtree(ou_id, person_id) do
  subtree_pattern = "#{ou_id}.%"

  Membership
  |> where([m], m.person_id == ^person_id)
  |> where([m], m.membership_status == :active)
  |> where(
    [m],
    m.ou_id == ^ou_id or like(m.ou_id, ^subtree_pattern)
  )
  |> join(:left, [m], ou in assoc(m, :ou))
  |> preload([m, ou], ou: ou)
  |> order_by([m], asc: m.ou_id)
  |> Repo.all()
end

# funcion para detectar si un miembro esta activo true, expelled false

def active_member?(ou_id, person_id)
    when is_binary(ou_id) and is_binary(person_id) do
  Membership
  |> where(
    [membership],
    membership.ou_id == ^ou_id and
      membership.person_id == ^person_id and
      membership.membership_status == :active
  )
  |> Repo.exists?()
end
end
