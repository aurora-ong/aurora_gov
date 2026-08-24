defmodule AuroraGov.CommandHandler.UpdateOUGoalHandler do
  @behaviour Commanded.Commands.Handler

  alias AuroraGov.Aggregate.OU
  alias AuroraGov.Command.UpdateOUGoal
  alias AuroraGov.Event.OUGoalUpdated

  # La OU todavía no existe en EventStore.
  def handle(%OU{ou_id: nil}, %UpdateOUGoal{}) do
    {:error, :ou_not_exists}
  end

  # La OU existe y está activa.
  def handle(
        %OU{ou_status: :active} = ou,
        %UpdateOUGoal{
          ou_id: ou_id,
          ou_goal: ou_goal
        }
      ) do
    cond do
      # Si objetivo es exactamente igual,
      # no tiene sentido generar un nuevo evento.
      ou.ou_goal == ou_goal ->
        {:error, :ou_goal_unchanged}

      true ->
        %OUGoalUpdated{
          ou_id: ou_id,
          ou_goal: ou_goal
        }
    end
  end

  # La OU existe, pero no está activa.
  def handle(_ou, %UpdateOUGoal{}) do
    {:error, :ou_not_active}
  end
end
