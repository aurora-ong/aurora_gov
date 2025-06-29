defmodule AuroraGov.Event.MembershipPromoted do
  @derive Jason.Encoder
  defstruct [:membership_id, :ou_id, :membership_status]
end
