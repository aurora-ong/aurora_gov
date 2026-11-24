defmodule AuroraGov.Test.Aggregate.LedgerTest do
  use ExUnit.Case, async: true

  alias AuroraGov.Aggregate.Ledger
  alias AuroraGov.Command.{CreateResource, CreateLedger, RecordTransaction}
  alias AuroraGov.Event.{ResourceCreated, LedgerCreated, TransactionRecorded}

  describe "CreateResource" do
    test "successfully creates a resource" do
      state = %Ledger{}
      cmd = %CreateResource{
        resource_id: "clp",
        name: "Pesos Chilenos",
        description: "Moneda de curso legal",
        unit_of_measure: "CLP$",
        ou_id: "barrio_vivo"
      }

      event = Ledger.execute(state, cmd)
      assert %ResourceCreated{resource_id: "clp", name: "Pesos Chilenos", unit_of_measure: "CLP$"} = event
      
      new_state = Ledger.apply(state, event)
      assert Map.has_key?(new_state.resources, "clp")
    end

    test "fails if resource already exists" do
      state = %Ledger{resources: %{"clp" => %{ou_id: "barrio_vivo"}}}
      cmd = %CreateResource{
        resource_id: "clp",
        name: "Pesos Chilenos",
        unit_of_measure: "CLP$"
      }

      assert {:error, :resource_already_exists} = Ledger.execute(state, cmd)
    end
  end

  describe "CreateLedger" do
    setup do
      state = %Ledger{}
      res_event = %ResourceCreated{resource_id: "clp", name: "Pesos", unit_of_measure: "CLP$", ou_id: "barrio_vivo"}
      state = Ledger.apply(state, res_event)
      %{state: state}
    end

    test "successfully creates a ledger account", %{state: state} do
      cmd = %CreateLedger{
        ledger_id: "1000000001",
        owner_id: "barrio_vivo",
        owner_type: "ou",
        ledger_type: "asset",
        resource_id: "clp",
        name: "Caja Chica"
      }

      assert %LedgerCreated{ledger_id: "1000000001", ledger_type: "asset", resource_id: "clp"} = Ledger.execute(state, cmd)
    end

    test "fails if resource does not exist", %{state: state} do
      cmd = %CreateLedger{
        ledger_id: "1000000001",
        owner_id: "barrio_vivo",
        owner_type: "ou",
        ledger_type: "asset",
        resource_id: "inexistente",
        name: "Caja Chica"
      }

      assert {:error, :resource_not_found} = Ledger.execute(state, cmd)
    end

    test "apply initializes balance to 0.0 and saves ledger_type", %{state: state} do
      event = %LedgerCreated{
        ledger_id: "1000000001",
        owner_id: "barrio_vivo",
        owner_type: "ou",
        ledger_type: "asset",
        resource_id: "clp",
        name: "Caja Chica"
      }

      new_state = Ledger.apply(state, event)
      acc = Map.get(new_state.ledgers, "1000000001")
      assert acc.ledger_type == "asset"
      assert Decimal.eq?(acc.balance, Decimal.new("0.0"))
    end
  end

  describe "RecordTransaction" do
    setup do
      state = %Ledger{}
      res_event = %ResourceCreated{resource_id: "clp", name: "Pesos", unit_of_measure: "CLP$", ou_id: "barrio_vivo"}
      state = Ledger.apply(state, res_event)

      res_hh = %ResourceCreated{resource_id: "hh", name: "Horas", unit_of_measure: "HH", ou_id: "barrio_vivo"}
      state = Ledger.apply(state, res_hh)

      # Cuenta Externa (mundo exterior)
      acc_ext = %LedgerCreated{ledger_id: "ext_1", owner_id: "donantes", owner_type: "external", ledger_type: "external", resource_id: "clp", name: "Donantes"}
      state = Ledger.apply(state, acc_ext)

      # Cuenta Activo A (Caja General)
      acc_asset_a = %LedgerCreated{ledger_id: "asset_a", owner_id: "barrio_vivo", owner_type: "ou", ledger_type: "asset", resource_id: "clp", name: "Caja General"}
      state = Ledger.apply(state, acc_asset_a)

      # Cuenta Activo B (Presupuesto Cultura)
      acc_asset_b = %LedgerCreated{ledger_id: "asset_b", owner_id: "cultura", owner_type: "ou", ledger_type: "asset", resource_id: "clp", name: "Cultura"}
      state = Ledger.apply(state, acc_asset_b)

      # Cuenta Horas
      acc_hh = %LedgerCreated{ledger_id: "hh_1", owner_id: "barrio_vivo", owner_type: "ou", ledger_type: "asset", resource_id: "hh", name: "Banco HH"}
      state = Ledger.apply(state, acc_hh)

      %{state: state}
    end

    test "fails when amount is zero or negative", %{state: state} do
      cmd = %RecordTransaction{
        transaction_id: "tx-1",
        origin_ledger_id: "ext_1",
        destination_ledger_id: "asset_a",
        amount: Decimal.new("0")
      }
      assert {:error, :invalid_amount} = Ledger.execute(state, cmd)

      cmd_neg = %{cmd | amount: Decimal.new("-500")}
      assert {:error, :invalid_amount} = Ledger.execute(state, cmd_neg)
    end

    test "fails when origin and destination are the same account", %{state: state} do
      cmd = %RecordTransaction{
        transaction_id: "tx-1",
        origin_ledger_id: "asset_a",
        destination_ledger_id: "asset_a",
        amount: Decimal.new("100")
      }
      assert {:error, :same_origin_and_destination} = Ledger.execute(state, cmd)
    end

    test "fails when accounts have mismatched resources", %{state: state} do
      cmd = %RecordTransaction{
        transaction_id: "tx-1",
        origin_ledger_id: "asset_a",
        destination_ledger_id: "hh_1",
        amount: Decimal.new("100")
      }
      assert {:error, :resource_mismatch} = Ledger.execute(state, cmd)
    end

    test "fails with :insufficient_funds when origin asset account has 0 or insufficient balance", %{state: state} do
      # asset_a tiene balance 0.0 inicialmente
      cmd = %RecordTransaction{
        transaction_id: "tx-1",
        origin_ledger_id: "asset_a",
        destination_ledger_id: "asset_b",
        amount: Decimal.new("1000")
      }
      assert {:error, :insufficient_funds} = Ledger.execute(state, cmd)
    end

    test "allows transfer from external account into asset account (funding)", %{state: state} do
      # Donación desde cuenta externa hacia Caja General
      cmd = %RecordTransaction{
        transaction_id: "tx-1",
        origin_ledger_id: "ext_1",
        destination_ledger_id: "asset_a",
        amount: Decimal.new("500000")
      }

      assert %TransactionRecorded{} = event = Ledger.execute(state, cmd)
      
      # Aplicar la transacción actualiza los balances en memoria
      new_state = Ledger.apply(state, event)
      assert Decimal.eq?(new_state.ledgers["ext_1"].balance, Decimal.new("-500000"))
      assert Decimal.eq?(new_state.ledgers["asset_a"].balance, Decimal.new("500000"))
    end

    test "allows transfer between asset accounts when origin has sufficient funds", %{state: state} do
      # Primero fondear asset_a con 500,000
      cmd_fund = %RecordTransaction{
        transaction_id: "tx-1",
        origin_ledger_id: "ext_1",
        destination_ledger_id: "asset_a",
        amount: Decimal.new("500000")
      }
      event_fund = Ledger.execute(state, cmd_fund)
      state = Ledger.apply(state, event_fund)

      # Ahora transferir 200,000 de asset_a hacia asset_b
      cmd_transfer = %RecordTransaction{
        transaction_id: "tx-2",
        origin_ledger_id: "asset_a",
        destination_ledger_id: "asset_b",
        amount: Decimal.new("200000")
      }
      assert %TransactionRecorded{} = event_tx = Ledger.execute(state, cmd_transfer)
      
      final_state = Ledger.apply(state, event_tx)
      assert Decimal.eq?(final_state.ledgers["asset_a"].balance, Decimal.new("300000"))
      assert Decimal.eq?(final_state.ledgers["asset_b"].balance, Decimal.new("200000"))

      # Intentar transferir más de lo disponible (300,001) debe fallar
      cmd_overdraft = %RecordTransaction{
        transaction_id: "tx-3",
        origin_ledger_id: "asset_a",
        destination_ledger_id: "asset_b",
        amount: Decimal.new("300001")
      }
      assert {:error, :insufficient_funds} = Ledger.execute(final_state, cmd_overdraft)
    end
  end
end
