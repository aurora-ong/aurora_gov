defmodule AuroraGov.Event.PersonRegistered do
  @derive Jason.Encoder
  defstruct [:person_id, :person_name, :person_mail]
end
