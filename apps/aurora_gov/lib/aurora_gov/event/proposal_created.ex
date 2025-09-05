defmodule AuroraGov.Event.ProposalCreated do
  @derive Jason.Encoder
  defstruct [
    :proposal_id,
    :proposal_title,
    :proposal_description,
    :proposal_ou_id,
    :proposal_owner_id,
    :proposal_power_id,
    :proposal_power_data,
    :proposal_ou_end,
    :proposal_power_sensibility
  ]
end
