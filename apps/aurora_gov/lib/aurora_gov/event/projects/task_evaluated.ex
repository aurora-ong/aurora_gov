defmodule AuroraGov.Event.TaskEvaluated do
  @derive Jason.Encoder
  defstruct [
    :ou_id,
    :project_id,
    :task_id,
    :review,
    :score
  ]
end
