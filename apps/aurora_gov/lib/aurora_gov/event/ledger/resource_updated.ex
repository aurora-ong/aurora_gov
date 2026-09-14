defmodule AuroraGov.Event.ResourceUpdated do
  @derive Jason.Encoder
  defstruct [:resource_id, :name, :description, :ou_id]
end
