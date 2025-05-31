defmodule AuroraGov.CommandHandler.StartMembershipHandler do
  @behaviour Commanded.Commands.Handler
  alias EventStore.UUID
  alias AuroraGov.Aggregate.{OU, Person}
  alias AuroraGov.Utils.OUTree
  alias AuroraGov.Command.StartMembership
  alias AuroraGov.Event.MembershipStarted

  def handle(%OU{ou_id: nil}, %StartMembership{}) do
    {:error, :ou_not_exists}
  end

  def handle(%OU{ou_status: :active} = uo, %StartMembership{
        ou_id: ou_id,
        person_id: person_id
      }) do
    with true <- check_person_exists(person_id),
         true <- check_membership_in_ou(uo, person_id),
         true <- check_membership_in_parent_ou(ou_id, person_id),
         do: %MembershipStarted{
           ou_id: ou_id,
           person_id: person_id,
           membership_id: UUID.uuid4()
         }
  end

  def handle(_ou, %StartMembership{}) do
    {:error, :ou_not_active}
  end

  defp check_membership_in_ou(ou, person_id) do
    if OU.has_active_membership?(ou, person_id) do
      {:error, :has_active_membership}
    else
      true
    end
  end

  defp check_membership_in_parent_ou(ou_id, person_id) do
    case OUTree.get_parent!(ou_id) do
      ^ou_id ->
        true

      parent ->
        parent_ou = AuroraGov.aggregate_state(OU, parent)

        if OU.has_active_membership?(parent_ou, person_id) do
          true
        else
          {:error, :parent_membership_missing}
        end
    end
  end

  defp check_person_exists(person_id) do
    case AuroraGov.aggregate_state(Person, person_id) do
      %Person{person_id: nil} ->
        {:error, :person_not_exists}

      _ ->
        true
    end
  end
end
