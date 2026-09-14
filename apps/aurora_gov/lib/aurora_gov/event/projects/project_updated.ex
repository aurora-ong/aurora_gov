defmodule AuroraGov.Event.ProjectUpdated do
  @derive [Jason.Encoder]
  defstruct [:project_id, :ou_id, :name, :description]
end
