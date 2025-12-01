defmodule AuroraGov.Event.ProposalConsumed do
  @derive Jason.Encoder
  defstruct [
    :proposal_id,
    :proposal_execution_result,
    :proposal_execution_error
  ]
end
