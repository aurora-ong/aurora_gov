defmodule AuroraGov.Context.PowerContext do
  @moduledoc """
  The Power context.
  """
  alias AuroraGov.Projector.Model.Power
  alias AuroraGov.Projector.Model.OUPower
  alias AuroraGov.Projector.Repo
  import Ecto.Query, warn: false

  ## Database getters

  def get_power_consensus_by_ou(_ou_id, _power_id) do
    power_consensus = Enum.random(1..100)
    n_total = 50
    n_required = floor(50 * power_consensus / 100)

    %{
      power_consensus: power_consensus,
      power_person_total: n_total,
      power_use_7_days: Enum.random(1..25),
      power_person_required: n_required
    }
  end

  def get_power_by_ou(ou_id) do
    query = from(p in Power, where: p.ou_id == ^ou_id)
    Repo.all(query)
  end

  def get_ou_power(ou_id) do
    query = from(p in OUPower, where: p.ou_id == ^ou_id)
    Repo.all(query)
  end
end
