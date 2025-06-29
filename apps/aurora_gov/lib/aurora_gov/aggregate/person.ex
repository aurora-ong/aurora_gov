defmodule AuroraGov.Aggregate.Person do
  alias AuroraGov.Event.PersonRegistered
  alias AuroraGov.Aggregate.Person
  defstruct [:person_id]

  def apply(_person, %PersonRegistered{person_id: person_id}) do
    %Person{
      person_id: person_id
    }
  end

  def get_person(person_id) do
    case AuroraGov.aggregate_state(Person, person_id) do
      %Person{person_id: nil} ->
        {:error, :person_not_exists}

      %Person{} = person ->
        {:person, person}
    end
  end
end
