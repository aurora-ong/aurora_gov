defmodule AuroraGov.ProcessManagers.ProposalExecutor do
  use Commanded.ProcessManagers.ProcessManager,
    name: "ProposalExecutor",
    application: AuroraGov,
    consistency: :strong

  alias AuroraGov.Event.ProposalExecuted
  alias AuroraGov.Event.ProposalConsumed
  require Logger

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
    # Tu lógica de construcción de comando se mueve aquí
    case build_proposal_command(event) do
      {:ok, proposal_command} ->
        # Al retornar el comando, Commanded hace el dispatch por ti
        Logger.debug("#{__MODULE__} Retornando comando #{inspect(proposal_command)}")

        [
          proposal_command,
          %AuroraGov.Command.ConsumeProposal{
            proposal_id: event.proposal_id,
            proposal_execution_result: :success
          }
        ]

      {:error, reason} ->
        # Opcional: Podrías emitir un comando para registrar la falla o compensar
        Logger.warning("#{__MODULE__} Error al generar comando #{inspect(reason)}")
        nil
    end
  end

    def error(error, %AuroraGov.Command.ConsumeProposal{}, failure_context) do
    Logger.error("El comando ConsumeProposal falló con razón: #{inspect(error)}")

    {:stop, :error}
  end

  def error({:error, reason}, _failed_command, failure_context) do
    Logger.warning("El comando falló con razón: #{inspect(reason)}")

    command = %AuroraGov.Command.ConsumeProposal{
      proposal_id: failure_context.process_manager_state.proposal_id,
      proposal_execution_result: :failed,
      proposal_execution_error: reason
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

  # Adaptación de tu función auxiliar para usar los datos del evento
  defp build_proposal_command(%ProposalExecuted{
         proposal_power_id: power_id,
         proposal_power_data: power_data
       }) do
    # Tu misma lógica de Ecto/Changeset, pero usando los datos que viajan en el evento
    with command_module <- AuroraGov.CommandUtils.find_command_by_id(power_id),
         %Ecto.Changeset{valid?: true} = changeset <- command_module.new(power_data),
         {:ok, proposal_command} <- Ecto.Changeset.apply_action(changeset, :register) do
      {:ok, proposal_command}
    else
      _ -> {:error, :invalid_power_data}
    end
  end
end
