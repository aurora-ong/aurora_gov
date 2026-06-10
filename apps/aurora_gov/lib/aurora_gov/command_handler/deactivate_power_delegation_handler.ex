defmodule AuroraGov.CommandHandler.DeactivatePowerDelegationHandler do
  @behaviour Commanded.Commands.Handler
  alias AuroraGov.Aggregate.OU
  alias AuroraGov.Command.DeactivatePowerDelegation
  alias AuroraGov.Event.PowerDelegationDeactivated

  def handle(%OU{ou_id: nil}, %DeactivatePowerDelegation{}) do
    {:error, :ou_not_exists}
  end

  def handle(%OU{ou_status: :active}, %DeactivatePowerDelegation{
        person_id: person_id,
        power_id: power_id,
        ou_id: ou_id
      }) do
    %PowerDelegationDeactivated{
      person_id: person_id,
      ou_id: ou_id,
      power_id: power_id
    }
  end

  def handle(%OU{}, %DeactivatePowerDelegation{}) do
    {:error, :ou_not_active}
  end
end
