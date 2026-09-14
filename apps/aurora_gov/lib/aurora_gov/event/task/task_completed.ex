defmodule AuroraGov.Event.TaskCompleted do
  @derive [Jason.Encoder]
  defstruct [:task_id, :project_id, :ou_id, :deliverable_evidence]
end
