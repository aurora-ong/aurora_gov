defmodule AuroraGov.Event.ProjectArchived do
  @derive Jason.Encoder
  defstruct [:ou_id, :project_id]
end
