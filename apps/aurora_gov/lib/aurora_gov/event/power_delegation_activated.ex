defmodule AuroraGov.Event.PowerDelegationActivated do
  @derive Jason.Encoder
  defstruct [:person_id, :ou_id, :power_id]
end
