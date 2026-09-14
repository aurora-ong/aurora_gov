defmodule AuroraGov.Event.TransactionRecorded do
  @derive Jason.Encoder
  defstruct [:transaction_id, :reference_id, :reference_type, :timestamp, :entries]
end
