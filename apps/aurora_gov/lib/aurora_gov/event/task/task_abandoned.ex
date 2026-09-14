defmodule AuroraGov.Event.TaskAbandoned do
  @derive [Jason.Encoder]
  defstruct [:task_id, :project_id, :ou_id]
end
