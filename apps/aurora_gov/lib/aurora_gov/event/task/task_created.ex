defmodule AuroraGov.Event.TaskCreated do
  @derive [Jason.Encoder]
  defstruct [:task_id, :project_id, :ou_id, :name, :description, :goal, :person_id]
end
