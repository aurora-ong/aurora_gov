defmodule AuroraGov.Event.MembershipDowngraded do
  @derive Jason.Encoder

  defstruct [:person_id, :ou_id, :membership_rank]
end
