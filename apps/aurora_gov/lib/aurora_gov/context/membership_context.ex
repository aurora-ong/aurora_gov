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
end
