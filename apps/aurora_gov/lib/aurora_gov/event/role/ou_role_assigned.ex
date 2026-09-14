defmodule AuroraGov.Event.OURoleAssigned do
  @derive Jason.Encoder
  defstruct [:ou_id, :role_id, :person_id]
end
