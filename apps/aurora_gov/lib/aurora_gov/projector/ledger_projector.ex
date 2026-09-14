defmodule AuroraGov.Projector.LedgerProjector do
  import Ecto.Query
  alias AuroraGov.Projector.Model.{Resource, Ledger, Transaction, Entry}
  alias AuroraGov.Event.{ResourceCreated, LedgerCreated, TransactionRecorded, ResourceUpdated}

  def project(%ResourceCreated{} = event, _metadata, multi) do
    changeset = Resource.changeset(%Resource{}, %{
      id: event.resource_id,
      name: event.name,
      description: event.description,
      is_fungible: event.is_fungible,
      unit_of_measure: event.unit_of_measure,
      ou_id: event.ou_id
    })

    multi
    |> Ecto.Multi.insert(:resource_insert, changeset)
    |> Ecto.Multi.run(:projector_update, fn _repo, %{resource_insert: resource} ->
      {:ok, {:resource_created, resource}}
    end)
  end

  def project(%ResourceUpdated{} = event, _metadata, multi) do
    query = from(r in Resource, where: r.id == ^event.resource_id)
    
    multi
    |> Ecto.Multi.update_all(:resource_update, query, set: [
      name: event.name,
      description: event.description,
      updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    ])
    |> Ecto.Multi.run(:projector_update, fn repo, _changes ->
      updated_resource = repo.get!(Resource, event.resource_id)
      {:ok, {:resource_updated, updated_resource}}
    end)
  end

  def project(%LedgerCreated{} = event, _metadata, multi) do
    changeset = Ledger.changeset(%Ledger{}, %{
      ledger_id: event.ledger_id,
      owner_id: event.owner_id,
      owner_type: event.owner_type,
      ledger_type: event.ledger_type,
      resource_id: event.resource_id,
      name: event.name,
      description: event.description,
      balance: Decimal.new("0.0")
    })

    multi
    |> Ecto.Multi.insert(:ledger_insert, changeset)
    |> Ecto.Multi.run(:projector_update, fn _repo, %{ledger_insert: ledger} ->
      {:ok, {:ledger_created, ledger}}
    end)
  end

  def project(%TransactionRecorded{} = event, _metadata, multi) do
    tx_changeset = Transaction.changeset(%Transaction{}, %{
      transaction_id: event.transaction_id,
      reference_id: event.reference_id,
      reference_type: event.reference_type,
      timestamp: event.timestamp
    })

    multi = Ecto.Multi.insert(multi, :transaction_insert, tx_changeset)

    multi =
      event.entries
      |> Enum.with_index()
      |> Enum.reduce(multi, fn {entry, idx}, acc_multi ->
        amount_decimal =
          if is_binary(entry.amount), do: Decimal.new(entry.amount), else: entry.amount

        entry_changeset = Entry.changeset(%Entry{}, %{
          transaction_id: event.transaction_id,
          ledger_id: entry.ledger_id,
          resource_id: entry.resource_id,
          amount: amount_decimal,
          description: Map.get(entry, :description)
        })

        acc_multi
        |> Ecto.Multi.insert({:entry_insert, idx}, entry_changeset)
        |> Ecto.Multi.update_all(
          {:ledger_update, idx},
          from(a in Ledger, where: a.ledger_id == ^entry.ledger_id),
          inc: [balance: amount_decimal]
        )
      end)

    Ecto.Multi.run(multi, :projector_update, fn _repo, %{transaction_insert: tx} ->
      {:ok, {:transaction_recorded, tx}}
    end)
  end
end
