defmodule AuroraGov.CommandHandler.ExpelMembershipHandler do
  @behaviour Commanded.Commands.Handler

  alias AuroraGov.Aggregate.OU
  alias AuroraGov.Command.ExpelMembership
  alias AuroraGov.Event.MembershipExpelled

  def handle(%OU{ou_id: nil}, %ExpelMembership{}) do
    {:error, :ou_not_exists}
  end

  def handle(
        %OU{ou_status: :active} = ou,
        %ExpelMembership{
          ou_id: ou_id,
          person_id: person_id
        }
      ) do
    case OU.get_membership(ou, person_id) do
      {:membership, %OU.Membership{membership_status: :active}} ->
        %MembershipExpelled{
          ou_id: ou_id,
          person_id: person_id
        }

      {:membership, %OU.Membership{membership_status: :expelled}} ->
        {:error, :membership_already_expelled}

      {:error, _reason} ->
        {:error, :membership_not_found}
    end
  end

  def handle(_ou, %ExpelMembership{}) do
    {:error, :ou_not_active}
  end
end
