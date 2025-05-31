defmodule AuroraGov.CommandHandler.RegisterPersonHandler do
  @behaviour Commanded.Commands.Handler
  alias AuroraGov.Aggregate.Person
  alias AuroraGov.Command.RegisterPerson
  alias AuroraGov.Event.PersonRegistered

  def handle(%Person{person_id: nil}, %RegisterPerson{
        person_id: person_id,
        person_name: person_name,
        person_mail: person_mail
      }) do
    %PersonRegistered{
      person_id: person_id,
      person_name: person_name,
      person_mail: person_mail
    }
  end

  def handle(%{} = _aggregate, %RegisterPerson{} = _command) do
    {:error, :person_already_exists}
  end
end
