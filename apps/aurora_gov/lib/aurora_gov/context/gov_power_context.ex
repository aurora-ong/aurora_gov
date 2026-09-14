defmodule AuroraGov.Context.GovPowerContext do
  @moduledoc """
  The GovPower context.
  """
  import Ecto.Query, warn: false

  @proposable_power [
    Elixir.AuroraGov.Command.StartMembership,
    Elixir.AuroraGov.Command.CreateOU,
    Elixir.AuroraGov.Command.PromoteMembership,
    Elixir.AuroraGov.Command.CreateRole,
    Elixir.AuroraGov.Command.AssignRole,
    Elixir.AuroraGov.Command.UnassignRole,
    Elixir.AuroraGov.Command.ArchiveRole,
    Elixir.AuroraGov.Command.CreateProject,
    Elixir.AuroraGov.Command.UpdateProject,
    Elixir.AuroraGov.Command.ArchiveProject,
    Elixir.AuroraGov.Command.TransferProject,
    Elixir.AuroraGov.Command.CreateTask,
    Elixir.AuroraGov.Command.UpdateTask,
    Elixir.AuroraGov.Command.AssignTask,
    Elixir.AuroraGov.Command.CompleteTask,
    Elixir.AuroraGov.Command.AbandonTask,
    Elixir.AuroraGov.Command.CancelTask,
    Elixir.AuroraGov.Command.EvaluateTask,
    Elixir.AuroraGov.Command.CreateResource,
    Elixir.AuroraGov.Command.UpdateResource,
    Elixir.AuroraGov.Command.CreateLedger,
    Elixir.AuroraGov.Command.RecordTransaction
  ]

  def list_gov_power do
    @proposable_power
    |> Enum.map(& &1.gov_power())
  end

  def get_gov_power(power_id) do
    case Enum.find(list_gov_power(), fn info ->
           info.id == power_id
         end) do
      nil -> {:error, :not_found}
      power -> {:ok, power}
    end
  end

  def get_gov_power!(power_id) do
    Enum.find(list_gov_power(), fn info ->
      info.id == power_id
    end) ||
      raise "Gov power not found: #{power_id}"
  end
end
