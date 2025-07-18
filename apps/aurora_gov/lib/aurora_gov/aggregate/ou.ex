defmodule AuroraGov.Aggregate.OU do
  defstruct [:ou_id, :ou_status, :ou_membership, :ou_power]

  defmodule Membership do
    defstruct [:membership_status]
  end

  defmodule Power do
    defstruct [:membership_id, :power_id, :power_value, :power_updated_at]
  end

  alias AuroraGov.Aggregate.OU
  alias AuroraGov.Event.{OUCreated, MembershipStarted, MembershipPromoted, PowerUpdated}

  # State mutators

  def apply(_uo, %OUCreated{ou_id: ou_id}) do
    %OU{
      ou_id: ou_id,
      ou_status: :active,
      ou_membership: %{},
      ou_power: %{}
    }
  end

  def apply(%OU{} = ou, %MembershipStarted{person_id: person_id}) do
    %OU{
      ou
      | ou_membership:
          Map.put(ou.ou_membership, person_id, %Membership{
            membership_status: :junior
          })
    }
  end

  def apply(%OU{} = ou, %MembershipPromoted{
        person_id: person_id,
        membership_status: membership_status
      }) do
    %OU{
      ou
      | ou_membership:
          Map.update!(ou.ou_membership, person_id, fn membership ->
            %Membership{
              membership
              | membership_status: membership_status
            }
          end)
    }
  end

  def apply(%OU{} = ou, %PowerUpdated{
        person_id: person_id,
        power_id: power_id,
        power_value: power_value,
        power_updated_at: power_updated_at
      }) do
    updated_power_map =
      Map.update(
        ou.ou_power || %{},
        power_id,
        %{
          person_id => %Power{
            power_id: power_id,
            power_value: power_value,
            power_updated_at: power_updated_at
          }
        },
        fn power_map ->
          Map.update(
            power_map,
            person_id,
            %Power{
              power_id: power_id,
              power_value: power_value,
              power_updated_at: power_updated_at
            },
            fn power ->
              %Power{
                power
                | power_value: power_value,
                  power_updated_at: power_updated_at
              }
            end
          )
        end
      )

    %OU{ou | ou_power: updated_power_map}
  end

  # Functions
  def get_ou(ou_id) when is_nil(ou_id), do: {:error, :ou_not_exists}

  def get_ou(ou_id) do
    case AuroraGov.aggregate_state(OU, ou_id) do
      %OU{ou_id: nil} -> {:error, :ou_not_exists}
      %OU{} = ou -> {:ou, ou}
    end
  end

  def get_membership(%OU{ou_membership: ou_membership}, person_id) do
    case Map.fetch(ou_membership, person_id) do
      :error -> {:error, :membership_not_found}
      {:ok, %Membership{} = membership} -> {:membership, membership}
    end
  end

  def get_person_power(%OU{ou_power: ou_power}, power_id, person_id) do
    case get_in(ou_power, [power_id, person_id]) do
      nil -> {:error, :power_not_found}
      %Power{} = power -> {:power, power}
    end
  end
end
