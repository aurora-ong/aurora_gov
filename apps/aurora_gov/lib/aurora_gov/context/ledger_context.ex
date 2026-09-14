defmodule AuroraGov.Context.LedgerContext do
  import Ecto.Query, warn: false
  alias AuroraGov.Projector.Repo
  alias AuroraGov.Projector.Model.{Resource, Ledger, Entry}

  def list_resources do
    Repo.all(Resource)
  end

  def list_resources_by_ou(ou_id) do
    Resource
    |> where([r], r.ou_id == ^ou_id)
    |> Repo.all()
  end

  def get_resource(id) do
    Repo.get(Resource, id)
  end

  def list_ledgers_by_ou(ou_id) do
    query = from a in Ledger, where: a.owner_id == ^ou_id and a.owner_type == :ou, preload: [:resource]
    Repo.all(query)
  end

  def list_external_ledgers do
    query = from a in Ledger, where: a.owner_type == :external, preload: [:resource]
    Repo.all(query)
  end

  def list_ledgers_by_owner(owner_id, owner_type \\ :project) do
    owner_type_enum = if is_binary(owner_type), do: String.to_atom(owner_type), else: owner_type
    query = from a in Ledger, where: a.owner_id == ^owner_id and a.owner_type == ^owner_type_enum, preload: [:resource]
    Repo.all(query)
  end

  def get_ledger(id) do
    Repo.get(Ledger, id) |> Repo.preload(:resource)
  end

  def get_ledger_balance(ledger_id) do
    query =
      from e in Entry,
      where: e.ledger_id == ^ledger_id,
      select: sum(e.amount)
      
    Repo.one(query) || Decimal.new("0.0")
  end
  
  def get_ledger_balances_with_resource(owner_id) do
    query =
      from a in Ledger,
      where: a.owner_id == ^owner_id,
      join: r in Resource, on: a.resource_id == r.resource_id,
      left_join: e in Entry, on: e.ledger_id == a.ledger_id,
      group_by: [a.ledger_id, a.name, r.name, r.unit_of_measure, r.is_fungible],
      select: %{
        ledger_id: a.ledger_id,
        ledger_name: a.name,
        resource_name: r.name,
        unit: r.unit_of_measure,
        fungible: r.is_fungible,
        balance: coalesce(sum(e.amount), 0.0)
      }
      
    Repo.all(query)
  end

  def list_ledger_entries(ledger_id) do
    query =
      from e in Entry,
      where: e.ledger_id == ^ledger_id,
      join: t in AuroraGov.Projector.Model.Transaction, on: e.transaction_id == t.transaction_id,
      order_by: [desc: t.timestamp],
      select: %{
        amount: e.amount,
        transaction_id: t.transaction_id,
        reference_id: t.reference_id,
        reference_type: t.reference_type,
        timestamp: t.timestamp,
        description: e.description
      }
      
    Repo.all(query)
  end
end
