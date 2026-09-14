defmodule AuroraGov.Event.OURoleArchived do
  @derive Jason.Encoder
  defstruct [:ou_id, :role_id]
end
