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

  def get_all_ou() do
    Repo.all(OU)
  end

  def get_ou_by_id(id) do
    Repo.get(OU, id)
  end

end
