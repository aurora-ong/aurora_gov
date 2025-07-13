defmodule AuroraGov.CommandHandler.PromoteMembershipHandler do
  @behaviour Commanded.Commands.Handler
  alias AuroraGov.Aggregate.OU
  alias AuroraGov.Command.PromoteMembership
  alias AuroraGov.Event.MembershipPromoted

  def handle(%OU{ou_id: nil}, %PromoteMembership{}) do
    {:error, :ou_not_exists}
  end

  def handle(%OU{ou_status: :active} = ou, %PromoteMembership{
        ou_id: ou_id,
        person_id: person_id
      }) do
    with {:membership, %OU.Membership{} = membership} <- OU.get_membership(ou, person_id),
         {:ok, membership_status} <- get_next_stament(membership) do
      %MembershipPromoted{
        ou_id: ou_id,
        person_id: person_id,
        membership_status: membership_status
      }
    end
  end

  def handle(_ou, %PromoteMembership{}) do
    {:error, :ou_not_active}
  end

  defp get_next_stament(%OU.Membership{membership_status: membership_status}) do
    cond do
      membership_status == :junior -> {:ok, :regular}
      membership_status == :regular -> {:ok, :senior}
      true -> {:error, :max_state_reached}
    end
  end
end
