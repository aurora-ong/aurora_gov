defmodule AuroraGov.Event.PowerUpdated do
  @derive Jason.Encoder
  defstruct [:person_id, :ou_id, :power_id, :power_value, :power_updated_at]
end
