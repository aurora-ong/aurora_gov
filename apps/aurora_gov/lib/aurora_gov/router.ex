defmodule AuroraGov.Router do
  use Commanded.Commands.Router
  alias AuroraGov.Command.{RegisterPerson, CreateOU, StartMembership}
  alias AuroraGov.CommandHandler.{RegisterPersonHandler, CreateOUHandler, StartMembershipHandler}
  alias AuroraGov.Aggregate.{Person, OU}

  dispatch RegisterPerson, to: RegisterPersonHandler, aggregate: Person, identity: :person_id
  dispatch CreateOU, to: CreateOUHandler, aggregate: OU, identity: :ou_id
  dispatch StartMembership, to: StartMembershipHandler, aggregate: OU, identity: :ou_id

end
