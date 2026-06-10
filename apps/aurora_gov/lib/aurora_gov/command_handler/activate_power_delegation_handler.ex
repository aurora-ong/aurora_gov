defmodule AuroraGov.CommandHandler.ActivatePowerDelegationHandler do
  @behaviour Commanded.Commands.Handler
  alias AuroraGov.Aggregate.OU
  alias AuroraGov.Command.ActivatePowerDelegation
  alias AuroraGov.Event.PowerDelegationActivated

  def handle(%OU{ou_id: nil}, %ActivatePowerDelegation{}) do
    {:error, :ou_not_exists}
  end

  # Validamos que la unidad de destino esté activa
  def handle(%OU{ou_status: :active} = ou, %ActivatePowerDelegation{
        person_id: person_id,
        power_id: power_id,
        ou_id: ou_id
      }) do
    with {:ok, parent_ou_id} <- check_root_ou(ou_id),
         :ok <- check_not_in_target_ou(ou, person_id),
         :ok <- check_parent_ou_membership(parent_ou_id, person_id) do
      IO.inspect(parent_ou_id, label: "Parent")

      %PowerDelegationActivated{
        person_id: person_id,
        ou_id: ou_id,
        power_id: power_id,
      }
    end
  end

  def handle(%OU{}, %ActivatePowerDelegation{}) do
    {:error, :ou_not_active}
  end

  defp check_root_ou(ou_id) do
    case AuroraGov.Utils.OUTree.get_parent(ou_id) do
      nil -> {:error, :ou_is_root}
      parent -> {:ok, parent}
    end
  end

  defp check_not_in_target_ou(ou, person_id) do
    case OU.get_membership(ou, person_id) do
      {:membership, _} -> {:error, :user_belongs_to_delegated_ou}
      {:error, :membership_not_found} -> :ok
    end
  end

  defp check_parent_ou_membership(parent_ou_id, person_id) do
    # Solicitamos el estado del agregado de la unidad superior para validar los requisitos
    case OU.get_ou(parent_ou_id) do
      {:ou, %OU{ou_status: :active} = parent_ou} ->
        case OU.get_membership(parent_ou, person_id) do
          {:membership, %OU.Membership{membership_rank: rank}}
          when rank in ["senior", "regular"] ->
            :ok

          {:membership, _} ->
            {:error, :insufficient_rank_in_parent_ou}

          {:error, :membership_not_found} ->
            {:error, :not_member_of_parent_ou}
        end

      {:ou, %OU{}} ->
        {:error, :parent_ou_not_active}

      {:error, :ou_not_exists} ->
        {:error, :parent_ou_not_exists}
    end
  end
end
