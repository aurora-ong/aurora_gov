defmodule AuroraGov.Context.MembershipContext do
  @moduledoc """
  The Persons context.
  """

  import Ecto.Query, warn: false

  alias AuroraGov.Projector.Repo
  alias AuroraGov.Projector.Model.Membership

  ## Database getters

  def get_all_membership_by_uo(ou_id) do
    query = from(m in Membership, where: m.ou_id == ^ou_id, preload: [:person])
    Repo.all(query)
  end

  def get_membership(ou_id, person_id) do
    query = from(m in Membership, where: m.ou_id == ^ou_id and m.person_id == ^person_id)
    Repo.all(query)
  end
end
