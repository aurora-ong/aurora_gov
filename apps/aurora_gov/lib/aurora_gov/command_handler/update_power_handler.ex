defmodule AuroraGov.CommandHandler.UpdatePowerHandler do
  @behaviour Commanded.Commands.Handler
  alias AuroraGov.Aggregate.OU
  alias AuroraGov.Command.UpdatePower
  alias AuroraGov.Event.PowerUpdated

  def handle(%OU{ou_id: nil}, %UpdatePower{}) do
    {:error, :ou_not_exists}
  end

  def handle(%OU{ou_status: :active} = ou, %UpdatePower{
        membership_id: membership_id,
        power_id: power_id,
        ou_id: ou_id,
        power_value: power_value
      }) do
    with {:membership, %OU.Membership{} = membership} <-
           OU.get_membership_by_id(ou, membership_id),
         :ok <- check_membership_status(membership),
         power <- OU.get_power_by_membership(ou, power_id, membership_id),
         :ok <- check_power_constrains(power) do
      IO.inspect(membership, label: "Membership")
      IO.inspect(power, label: "Power")

      %PowerUpdated{
        membership_id: membership_id,
        ou_id: ou_id,
        power_id: power_id,
        power_value: power_value,
        power_updated_at: DateTime.utc_now()
      }
    else
      error -> IO.inspect(error, label: "Error")
    end
  end

  defp check_membership_status(%OU.Membership{membership_status: membership_status}) do
    cond do
      membership_status == :junior -> {:error, :insufficient_power}
      true -> :ok
    end
  end

  defp check_power_constrains({:error, :power_not_found}), do: :ok

  defp check_power_constrains({:power, %OU.Power{power_updated_at: _power_updated_at}}) do
    # TODO COMPROBAR QUE HAYAN PASADO 24 HORAS
    :ok
  end
end
