defmodule AuroraGov.Event.ProjectCreated do
  @derive Jason.Encoder
  defstruct [:ou_id, :project_id, :name, :description]
end
