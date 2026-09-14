defmodule AuroraGov.Event.TaskAssigned do
  @derive [Jason.Encoder]
  defstruct [:task_id, :project_id, :ou_id, :person_id, :estimated_delivery_at]
end
