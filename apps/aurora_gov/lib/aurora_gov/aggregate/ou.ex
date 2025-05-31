defmodule AuroraGov.Aggregate.OU do
  defstruct [:ou_id, :ou_status, :ou_membership]

  alias AuroraGov.Aggregate.OU
  alias AuroraGov.Event.{OUCreated, MembershipStarted}


  # State mutators

  def apply(_uo, %OUCreated{ou_id: ou_id}) do
    %OU{
      ou_id: ou_id,
      ou_status: :active,
      ou_membership: %{}
    }
  end

  def apply(%OU{} = ou, %MembershipStarted{person_id: person_id}) do
    %OU{ ou |
      ou_membership: Map.put(ou.ou_membership, person_id, :junior)
    }
  end

  # Functions

  def has_active_membership?(%OU{ou_membership: ou_membership}, person_id) do
    Map.has_key?(ou_membership, person_id)
  end

  def get_active_membership!(%OU{ou_membership: ou_membership}, person_id) do
    case Map.get(ou_membership, person_id) do
      nil -> {:error, :membership_not_active}
      membership -> membership
    end
  end
end
