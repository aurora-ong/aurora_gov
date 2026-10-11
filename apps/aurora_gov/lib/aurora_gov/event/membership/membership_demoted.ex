defmodule AuroraGov.Event.MembershipDemoted do
  @derive Jason.Encoder

  defstruct [:person_id, :ou_id, :membership_rank]
end
