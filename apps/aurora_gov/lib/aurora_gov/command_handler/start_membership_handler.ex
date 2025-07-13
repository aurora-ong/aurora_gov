defmodule AuroraGov.CommandHandler.StartMembershipHandler do
  @behaviour Commanded.Commands.Handler
  alias AuroraGov.Utils.OUTree
    alias AuroraGov.Aggregate.{OU, Person}
  alias AuroraGov.Command.StartMembership
  alias AuroraGov.Event.MembershipStarted

  def handle(%OU{ou_id: nil}, %StartMembership{}) do
    {:error, :ou_not_exists}
  end

  def handle(%OU{ou_status: :active} = ou, %StartMembership{
        ou_id: ou_id,
        person_id: person_id
      }) do
    with {:person, _person} <- Person.get_person(person_id),
         {:error, :membership_not_found} <- OU.get_membership(ou, person_id),
         :ok <- check_parent_membership(ou_id, person_id) do
      %MembershipStarted{
        ou_id: ou_id,
        person_id: person_id
      }
    else
      {:membership, _} -> {:error, :membership_already_active}
      error -> error
    end
  end

  def handle(_ou, %StartMembership{}) do
    {:error, :ou_not_active}
  end

  def check_parent_membership(ou_id, person_id) do
    case OUTree.get_parent!(ou_id) do
      ^ou_id ->
        :ok

      parent ->
        with {:ou, ou} <- OU.get_ou(parent),
             {:membership, _membership} <- OU.get_membership(ou, person_id) do
          :ok
        else
          {:error, :membership_not_found} -> {:error, :parent_membership_not_found}
          error -> raise("Error: #{inspect(error)}")
        end
    end
  end
end
