defmodule AuroraGov.Event.MembershipRevoked do
  @derive Jason.Encoder

  defstruct [:person_id, :ou_id, :reason]

end
