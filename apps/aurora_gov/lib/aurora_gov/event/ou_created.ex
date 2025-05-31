defmodule AuroraGov.Event.OUCreated do
  @derive Jason.Encoder
  defstruct [:ou_id, :ou_name, :ou_goal, :ou_description]
end
