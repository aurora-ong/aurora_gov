defmodule AuroraGov.Context.OuPowerContext do
  @moduledoc """
  The Power context.
  """
  alias AuroraGov.Projector.Model.OUPower
  alias AuroraGov.Projector.Repo
  import Ecto.Query, warn: false

  def list_ou_power(ou_id) do
    query = from(p in OUPower, where: p.ou_id == ^ou_id)
    Repo.all(query)
  end

  def get_ou_power(ou_id, power_id) do
    query =
      from(p in OUPower, where: p.ou_id == ^ou_id and p.power_id == ^power_id)

    Repo.one(query)
  end
end
