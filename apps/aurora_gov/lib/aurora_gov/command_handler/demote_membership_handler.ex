defmodule AuroraGov.CommandHandler.DemoteMembershipHandler do
  @behaviour Commanded.Commands.Handler

  alias AuroraGov.Aggregate.OU
  alias AuroraGov.Command.DemoteMembership
  alias AuroraGov.Event.MembershipDemoted

  def handle(%OU{ou_id: nil}, %DemoteMembership{}) do
    {:error, :ou_not_exists}
  end

  def handle(
        %OU{ou_status: :active} = ou,
        %DemoteMembership{
          ou_id: ou_id,
          person_id: person_id
        }
      ) do
    with {:membership, %OU.Membership{} = membership} <-
           OU.get_membership(ou, person_id),
         {:ok, membership_rank} <-
           get_previous_rank(membership) do
      %MembershipDemoted{
        ou_id: ou_id,
        person_id: person_id,
        membership_rank: membership_rank
      }
    else
      {:error, _error} = error ->
        error
    end
  end

  def handle(_ou, %DemoteMembership{}) do
    {:error, :ou_not_active}
  end

  defp get_previous_rank(
         %OU.Membership{
           membership_rank: membership_rank
         }
       ) do
    cond do
      membership_rank == "senior" ->
        {:ok, "regular"}

      membership_rank == "regular" ->
        {:ok, "junior"}

      true ->
        {:error, :min_rank_reached}
    end
  end
end
