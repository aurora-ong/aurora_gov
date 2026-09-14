defmodule AuroraGov.Event.ProposalExecuted do
  @derive Jason.Encoder
  defstruct [
    :proposal_id,
    :proposal_power_id,
    :proposal_power_data
  ]
end
