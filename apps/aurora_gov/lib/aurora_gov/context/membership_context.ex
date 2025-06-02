defmodule AuroraGov.Projector.Membership do
  @moduledoc """
  The Persons context.
  """

  import Ecto.Query, warn: false

  alias AuroraGov.Projector.Repo
  alias AuroraGov.Projector.Model.Membership

  ## Database getters

  def get_all_membership_by_uo(ou_id) do
    query = from(m in Membership, where: m.ou_id == ^ou_id, preload: [:ou, :person])
    Repo.all(query)
  end

end
