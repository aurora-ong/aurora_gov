defmodule AuroraGov.Event.PowerUpdated do
  @derive Jason.Encoder
  defstruct [:membership_id, :ou_id, :power_id, :power_value, :power_updated_at]
end
