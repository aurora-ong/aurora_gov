defmodule AuroraGov.Event.LedgerCreated do
  @derive Jason.Encoder
  defstruct [:ledger_id, :owner_id, :owner_type, :ledger_type, :resource_id, :name, :description]
end
