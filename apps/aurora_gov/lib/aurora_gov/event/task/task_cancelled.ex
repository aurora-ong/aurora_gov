defmodule AuroraGov.Event.TaskCancelled do
  @derive [Jason.Encoder]
  defstruct [:task_id, :project_id, :ou_id]
end
