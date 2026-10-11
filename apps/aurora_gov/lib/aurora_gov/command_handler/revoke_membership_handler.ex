defmodule AuroraGov.CommandHandler.RevokeMembershipHandler do
  @behaviour Commanded.Commands.Handler

  alias AuroraGov.Aggregate.OU
  alias AuroraGov.Command.RevokeMembership
  alias AuroraGov.Event.MembershipRevoked

  def handle(%OU{ou_id: nil}, %RevokeMembership{}) do
    {:error, :ou_not_exists}
  end

  def handle(
        %OU{ou_status: :active} = ou,
        %RevokeMembership{
          ou_id: ou_id,
          person_id: person_id,
          reason: reason
        }
      ) do
    case OU.get_membership(ou, person_id) do
      {:membership, %OU.Membership{}} ->
        %MembershipRevoked{
          ou_id: ou_id,
          person_id: person_id,
          reason: reason
        }

      {:error, _reason} ->
        {:error, :membership_not_found}
    end
  end

  def handle(_ou, %RevokeMembership{}) do
    {:error, :ou_not_active}
  end
end
