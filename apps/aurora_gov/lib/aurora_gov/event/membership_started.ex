defmodule AuroraGov.Event.MembershipStarted do
  @derive Jason.Encoder
  defstruct [:membership_id, :ou_id, :person_id]
end
