defmodule AuroraGov.Aggregate.Ledger do
  @moduledoc """
  Agregado raíz para el sistema de contabilidad por partida doble (Ledger).
  Valida la existencia de recursos y cuentas, y asegura que toda transacción
  esté matemáticamente balanceada (suma cero).
  """

  defstruct resources: %{}, ledgers: %{}

  alias AuroraGov.Aggregate.Ledger
  alias AuroraGov.Command.{CreateResource, CreateLedger, RecordTransaction, UpdateResource}
  alias AuroraGov.Event.{ResourceCreated, LedgerCreated, TransactionRecorded, ResourceUpdated}

  # --- Comandos ---

  def execute(%Ledger{resources: res}, %CreateResource{} = cmd) do
    if Map.has_key?(res, cmd.resource_id) do
      {:error, :resource_already_exists}
    else
      %ResourceCreated{
        resource_id: cmd.resource_id,
        name: cmd.name,
        description: cmd.description,
        unit_of_measure: cmd.unit_of_measure,
        ou_id: cmd.ou_id
      }
    end
  end

  def execute(%Ledger{resources: res}, %UpdateResource{} = cmd) do
    case Map.get(res, cmd.resource_id) do
      nil -> {:error, :resource_not_found}
      resource ->
        if resource.ou_id != cmd.ou_id and not is_nil(resource.ou_id) do
          {:error, :unauthorized_owner}
        else
          %ResourceUpdated{
            resource_id: cmd.resource_id,
            name: cmd.name,
            description: cmd.description,
            ou_id: cmd.ou_id
          }
        end
    end
  end

  def execute(%Ledger{ledgers: ledgers, resources: resources}, %CreateLedger{} = cmd) do
    if Map.has_key?(ledgers, cmd.ledger_id) do
      {:error, :ledger_already_exists}
    else
      if not Map.has_key?(resources, cmd.resource_id) do
         {:error, :resource_not_found}
      else
        %LedgerCreated{
          ledger_id: cmd.ledger_id,
          owner_id: cmd.owner_id,
          owner_type: cmd.owner_type,
          ledger_type: cmd.ledger_type,
          resource_id: cmd.resource_id,
          name: cmd.name,
          description: cmd.description
        }
      end
    end
  end

  def execute(%Ledger{ledgers: ledgers}, %RecordTransaction{} = cmd) do
    amount_decimal = if is_binary(cmd.amount), do: Decimal.new(cmd.amount), else: cmd.amount

    cond do
      is_nil(amount_decimal) or Decimal.compare(amount_decimal, Decimal.new("0")) != :gt ->
        {:error, :invalid_amount}

      cmd.origin_ledger_id == cmd.destination_ledger_id ->
        {:error, :same_origin_and_destination}

      not Map.has_key?(ledgers, cmd.origin_ledger_id) ->
        {:error, :origin_ledger_not_found}

      not Map.has_key?(ledgers, cmd.destination_ledger_id) ->
        {:error, :destination_ledger_not_found}

      true ->
        origin_ledger_data = Map.get(ledgers, cmd.origin_ledger_id)
        dest_ledger_data = Map.get(ledgers, cmd.destination_ledger_id)
        resource_id = origin_ledger_data.resource_id

        is_asset = origin_ledger_data.ledger_type in ["asset", :asset]
        origin_balance = Map.get(origin_ledger_data, :balance, Decimal.new("0.0"))

        cond do
          dest_ledger_data.resource_id != resource_id ->
            {:error, :resource_mismatch}

          is_asset and Decimal.compare(origin_balance, amount_decimal) == :lt ->
            {:error, :insufficient_funds}

          true ->
            entries = [
              %{
                ledger_id: cmd.origin_ledger_id,
                resource_id: resource_id,
                amount: Decimal.negate(amount_decimal),
                description: cmd.description
              },
              %{
                ledger_id: cmd.destination_ledger_id,
                resource_id: resource_id,
                amount: amount_decimal,
                description: cmd.description
              }
            ]

            %TransactionRecorded{
              transaction_id: cmd.transaction_id,
              reference_id: cmd.reference_id,
              reference_type: cmd.reference_type,
              timestamp: cmd.timestamp || DateTime.utc_now(),
              entries: entries
            }
        end
    end
  end

  # --- Aplicadores de Estado ---

  def apply(%Ledger{} = ledger, %ResourceCreated{resource_id: id, ou_id: ou_id}) do
    %Ledger{ledger | resources: Map.put(ledger.resources, id, %{ou_id: ou_id})}
  end

  def apply(%Ledger{} = ledger, %ResourceUpdated{resource_id: id, ou_id: ou_id}) do
    %Ledger{ledger | resources: Map.put(ledger.resources, id, %{ou_id: ou_id})}
  end

  def apply(%Ledger{} = ledger, %LedgerCreated{} = event) do
    ledger_data = %{
      resource_id: event.resource_id,
      ledger_type: to_string(event.ledger_type),
      balance: Decimal.new("0.0")
    }

    %Ledger{ledger | ledgers: Map.put(ledger.ledgers, event.ledger_id, ledger_data)}
  end

  def apply(%Ledger{} = ledger, %TransactionRecorded{entries: entries}) do
    updated_ledgers =
      Enum.reduce(entries, ledger.ledgers, fn entry, acc ->
        case Map.get(acc, entry.ledger_id) do
          nil ->
            acc

          account ->
            entry_amount =
              if is_binary(entry.amount), do: Decimal.new(entry.amount), else: entry.amount

            current_balance = Map.get(account, :balance, Decimal.new("0.0"))
            new_balance = Decimal.add(current_balance, entry_amount)

            Map.put(acc, entry.ledger_id, %{account | balance: new_balance})
        end
      end)

    %Ledger{ledger | ledgers: updated_ledgers}
  end
end
