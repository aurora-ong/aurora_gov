defmodule AuroraGov.ProcessManagers.ProposalExecutor do
  use Commanded.ProcessManagers.ProcessManager,
    name: "ProposalExecutor",
    application: AuroraGov,
    consistency: :strong

  alias AuroraGov.Event.ProposalExecuted
  alias AuroraGov.Event.ProposalConsumed
  require Logger

  alias AuroraGov.Command.{
  ConsumeProposal,
  ExpelMembership
}

  alias AuroraGov.Context.{
  GovPowerContext,
  MembershipContext
}


  @derive Jason.Encoder
  defstruct [:proposal_id]

  # Nos interesa iniciar este proceso cuando se consume una propuesta
  def interested?(%ProposalExecuted{proposal_id: proposal_id}), do: {:start, proposal_id}

  def interested?(%ProposalConsumed{proposal_id: proposal_id}), do: {:stop, proposal_id}

  def apply(%__MODULE__{} = state, %AuroraGov.Event.ProposalExecuted{} = event) do
    %__MODULE__{state | proposal_id: event.proposal_id}
  end

  # Manejamos el evento y retornamos el comando a despachar
 def handle(_state, %ProposalExecuted{} = event) do
  case build_proposal_commands(event) do
    {:ok, proposal_commands} ->
      Logger.debug(
        "#{__MODULE__} Retornando comandos #{inspect(proposal_commands)}"
      )

      proposal_commands ++
        [
          %ConsumeProposal{
            proposal_id: event.proposal_id,
            proposal_execution_result: :success
          }
        ]

    {:error, reason} ->
      Logger.warning(
        "#{__MODULE__} Error al generar comandos #{inspect(reason)}"
      )

      [
        %ConsumeProposal{
          proposal_id: event.proposal_id,
          proposal_execution_result: :failed,
          proposal_execution_error: inspect(reason)
        }
      ]
  end
end

  def error(error, %AuroraGov.Command.ConsumeProposal{}, _failure_context) do
    Logger.error("El comando ConsumeProposal falló con razón: #{inspect(error)}")

    {:stop, :error}
  end

  def error({:error, reason}, _failed_command, failure_context) do
    Logger.warning("El comando falló con razón: #{inspect(reason)}")

    command = %AuroraGov.Command.ConsumeProposal{
      proposal_id: failure_context.process_manager_state.proposal_id,
      proposal_execution_result: :failed,
      proposal_execution_error: inspect(reason)
    }

    {:continue, [command], %{}}
  end

  def error(error, _command, _context) do
    Logger.error(
      "ProposalExecutor: Error NO previsto. Ignorando para no matar la suscripción. Error: #{inspect(error)}"
    )

    # :skip marca el evento como procesado y sigue adelante.
    # Es más seguro que :stop si no sabes qué pasó.
    :skip
  end


# cuando la propuesta aprobada corresponde solo a org.membership.expel ingresa aca
defp build_proposal_commands(%ProposalExecuted{
       proposal_power_id: "org.membership.expel",
       proposal_power_data: power_data
     }) do
  with {:ok, ou_id} <- get_power_value(power_data, :ou_id),
       {:ok, person_id} <- get_power_value(power_data, :person_id) do
    memberships =
      MembershipContext.list_active_memberships_in_ou_subtree(
        ou_id,
        person_id
      )

    case memberships do
      [] ->
        {:error, :no_active_memberships_in_subtree}

      memberships ->
        commands =
          Enum.map(memberships, fn membership ->
            %ExpelMembership{
              ou_id: membership.ou_id,
              person_id: person_id
            }
          end)

        Logger.info(
          "Expulsión en cascada de #{person_id}. " <>
            "OU afectadas: #{inspect(Enum.map(commands, & &1.ou_id))}"
        )

        {:ok, commands}
    end
  end
end

defp build_proposal_commands(%ProposalExecuted{} = event) do
  case build_proposal_command(event) do
    {:ok, command} ->
      {:ok, [command]}

    {:error, reason} ->
      {:error, reason}
  end
end

  defp build_proposal_command(%ProposalExecuted{
         proposal_power_id: power_id,
         proposal_power_data: power_data
       }) do
    with %AuroraGov.GovPower{module: command_module} <- AuroraGov.Context.GovPowerContext.get_gov_power!(power_id),
         %Ecto.Changeset{valid?: true} = changeset <- command_module.new(power_data),
         {:ok, proposal_command} <- Ecto.Changeset.apply_action(changeset, :register) do
      {:ok, proposal_command}
    else
      _ -> {:error, :invalid_power_data}
    end
  end

  defp get_power_value(power_data, key) when is_map(power_data) do
  value =
    Map.get(power_data, key) ||
      Map.get(power_data, Atom.to_string(key))

  case value do
    nil ->
      {:error, {:missing_power_data, key}}

    "" ->
      {:error, {:missing_power_data, key}}

    value ->
      {:ok, value}
  end
end
end
