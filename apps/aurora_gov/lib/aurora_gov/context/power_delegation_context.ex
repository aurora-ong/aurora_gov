defmodule AuroraGov.Context.PowerDelegationContext do
  @moduledoc """
  The PowerDelegation context.
  """
  alias AuroraGov.Projector.Model.PowerDelegation
  alias AuroraGov.Projector.Repo
  import Ecto.Query, warn: false

  def count_active_delegation(ou_id, power_id) do
    query =
      PowerDelegation
      |> where([m], m.ou_id == ^ou_id)
      |> where([m], m.power_id == ^power_id)

    Repo.aggregate(query, :count, :person_id)
  end

   def count_active_delegation_by_ou(ou_id) do
    query =
      from(p in PowerDelegation,
        where: p.ou_id == ^ou_id
      )

    Repo.one(query)
  end

  def get_user_delegation(person_id, power_id, ou_id) do
    query =
      from(p in PowerDelegation,
        where: p.person_id == ^person_id and p.power_id == ^power_id and p.ou_id == ^ou_id
      )

    Repo.one(query)
  end
end
