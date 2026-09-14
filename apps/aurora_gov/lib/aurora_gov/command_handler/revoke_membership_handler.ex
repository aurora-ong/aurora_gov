defmodule AuroraGov.CommandHandler.RevokeMembershipHandler do
  @behaviour Commanded.Commands.Handler

  alias AuroraGov.Aggregate.OU
  alias AuroraGov.Command.RevokeMembership
  alias AuroraGov.Event.MembershipRevoked
  alias AuroraGov.Context.MembershipContext

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
        memberships = MembershipContext.list_active_memberships_in_ou_subtree(ou_id, person_id)
        
        events = Enum.map(memberships, fn membership ->
          %MembershipRevoked{
            ou_id: membership.ou_id,
            person_id: person_id,
            reason: reason
          }
        end)
        
        if events == [] do
          %MembershipRevoked{
            ou_id: ou_id,
            person_id: person_id,
            reason: reason
          }
        else
          events
        end

      {:error, _reason} ->
        {:error, :membership_not_found}
    end
  end

  def handle(_ou, %RevokeMembership{}) do
    {:error, :ou_not_active}
  end
end
