defmodule AuroraGov.CommandHandler.PromoteMembershipHandler do
  @behaviour Commanded.Commands.Handler
  alias AuroraGov.Aggregate.OU
  alias AuroraGov.Command.PromoteMembership
  alias AuroraGov.Event.MembershipPromoted
  require Logger

  def handle(%OU{ou_id: nil}, %PromoteMembership{}) do
    {:error, :ou_not_exists}
  end

  def handle(%OU{ou_status: :active} = ou, %PromoteMembership{
        ou_id: ou_id,
        person_id: person_id
      }) do
    with {:membership, %OU.Membership{} = membership} <- OU.get_membership(ou, person_id),
         {:ok, membership_rank} <- get_next_rank(membership) do
      %MembershipPromoted{
        ou_id: ou_id,
        person_id: person_id,
        membership_rank: membership_rank
      }
    else
      {:error, _error} = error ->
        error
    end
  end

  def handle(_ou, %PromoteMembership{}) do
    {:error, :ou_not_active}
  end

  defp get_next_rank(%OU.Membership{membership_rank: membership_rank}) do
    cond do
      membership_rank == "junior" -> {:ok, "regular"}
      membership_rank == "regular" -> {:ok, "senior"}
      true -> {:error, :max_statement_reached}
    end
  end
end
