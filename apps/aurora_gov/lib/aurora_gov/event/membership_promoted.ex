defmodule AuroraGov.Event.MembershipPromoted do
  @derive Jason.Encoder
  defstruct [:person_id, :ou_id, :membership_status]
end
