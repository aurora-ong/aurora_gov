defmodule AuroraGov.Event.ResourceCreated do
  @derive Jason.Encoder
  defstruct [:resource_id, :name, :description, :is_fungible, :unit_of_measure, :ou_id]
end
