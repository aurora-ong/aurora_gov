defmodule AuroraGov.Event.MembershipStarted do
  @derive Jason.Encoder
  defstruct [:ou_id, :person_id]
end
