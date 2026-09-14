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
        is_fungible: cmd.is_fungible,
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
    # 1. Construir Asientos Contables a partir de los parámetros simples del comando
    amount_decimal = if is_binary(cmd.amount), do: Decimal.new(cmd.amount), else: cmd.amount
    
    # Obtener el resource_id de la cuenta de origen
    origin_ledger_data = Map.get(ledgers, cmd.origin_ledger_id)
    resource_id = if origin_ledger_data, do: origin_ledger_data.resource_id, else: nil

    entries = [
      %{ledger_id: cmd.origin_ledger_id, resource_id: resource_id, amount: Decimal.negate(amount_decimal), description: cmd.description},
      %{ledger_id: cmd.destination_ledger_id, resource_id: resource_id, amount: amount_decimal, description: cmd.description}
    ]

    # 2. Validar que la transacción sea de suma cero (Partida Doble)
    balances =
      entries
      |> Enum.reduce(%{}, fn entry, acc ->
        Map.update(acc, entry.resource_id, entry.amount, &Decimal.add(&1, entry.amount))
      end)
    
    non_zero = Enum.find(balances, fn {_res_id, sum} -> not Decimal.eq?(sum, Decimal.new("0.0")) end)
    
    if is_nil(resource_id) do
      {:error, :origin_ledger_not_found}
    else
      if non_zero do
        {:error, :transaction_not_balanced}
      else
        # 3. Validar que las cuentas afectadas existan
        missing_ledgers = Enum.filter(entries, fn entry -> not Map.has_key?(ledgers, entry.ledger_id) end)
        
        if length(missing_ledgers) > 0 do
          {:error, :ledger_not_found}
        else
          # 4. Validar que la cuenta de destino tenga el mismo recurso
          dest_ledger_data = Map.get(ledgers, cmd.destination_ledger_id)
          if dest_ledger_data.resource_id != resource_id do
            {:error, :resource_mismatch}
          else
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
    end
  end

  # --- Aplicadores de Estado ---

  def apply(%Ledger{} = ledger, %ResourceCreated{resource_id: id, ou_id: ou_id}) do
    %Ledger{ledger | resources: Map.put(ledger.resources, id, %{ou_id: ou_id})}
  end

  def apply(%Ledger{} = ledger, %ResourceUpdated{resource_id: id, ou_id: ou_id}) do
    %Ledger{ledger | resources: Map.put(ledger.resources, id, %{ou_id: ou_id})}
  end

  def apply(%Ledger{} = ledger, %LedgerCreated{ledger_id: id, resource_id: res_id}) do
    %Ledger{ledger | ledgers: Map.put(ledger.ledgers, id, %{resource_id: res_id})}
  end

  def apply(%Ledger{} = ledger, %TransactionRecorded{}) do
    # La transacción no modifica la existencia de recursos ni cuentas en memoria
    # El balance es manejado por el read model (Ecto)
    ledger
  end
end
