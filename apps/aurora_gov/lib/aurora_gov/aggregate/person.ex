defmodule AuroraGov.Aggregate.Person do
  alias AuroraGov.Event.PersonRegistered
  defstruct [:person_id]

  def apply(_person, %PersonRegistered{person_id: person_id}) do
    %{
      person_id: person_id
    }
  end

end
