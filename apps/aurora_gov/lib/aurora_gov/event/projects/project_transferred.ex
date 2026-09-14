defmodule AuroraGov.Event.ProjectTransferred do
  @derive Jason.Encoder
  defstruct [:ou_id, :project_id, :destination_ou_id]
end
