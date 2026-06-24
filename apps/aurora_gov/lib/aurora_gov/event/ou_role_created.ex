defmodule AuroraGov.Event.OURoleCreated do
  @derive Jason.Encoder
  defstruct [:ou_id, :role_id, :role_name, :role_description]
end
