defmodule AuroraGov.Aggregate.Proposal do
  require Logger

  defstruct [
    :proposal_id,
    :proposal_ou_end_id,
    :proposal_owner_id,
    :proposal_power_id,
    :proposal_power_data,
    # :active | :consumed
    :proposal_status,
    # %{person_id => %Vote{}}
    :proposal_votes,
    # %{ou_id => sensibility_value}
    :proposal_power_sensibility
  ]

  @type status :: :active | :executing | :consumed
  @type vote_type :: :direct | :represented

  defmodule Vote do
    defstruct [
      # [ou_id]
      :ou_id,
      :vote_id,
      # -1 | 0 | 1
      :vote_value
    ]
  end

  # Ejemplo de evento para registrar una propuesta
  def apply(
        _proposal,
        %AuroraGov.Event.ProposalCreated{
          proposal_id: proposal_id,
          proposal_owner_id: proposal_owner_id,
          proposal_power_id: proposal_power_id,
          proposal_power_data: proposal_power_data,
          proposal_power_sensibility: power_sensibility,
          proposal_ou_end_id: proposal_ou_end_id
        } = event
      ) do
    proposal_votes = calculate_proposal_votes(event)

    %__MODULE__{
      proposal_id: proposal_id,
      proposal_ou_end_id: proposal_ou_end_id,
      proposal_owner_id: proposal_owner_id,
      proposal_power_id: proposal_power_id,
      proposal_power_data: proposal_power_data,
      proposal_status: :active,
      proposal_votes: proposal_votes,
      proposal_power_sensibility: power_sensibility
    }
  end

  def apply(%__MODULE__{proposal_votes: proposal_votes} = proposal, %AuroraGov.Event.VoteEmited{
        person_id: person_id,
        vote_id: vote_id,
        vote_value: vote_value
      }) do
    updated_votes =
      Map.update(
        proposal_votes || %{},
        person_id,
        %Vote{vote_id: vote_id, vote_value: vote_value},
        fn vote ->
          %Vote{vote | vote_id: vote_id, vote_value: vote_value}
        end
      )

    %__MODULE__{proposal | proposal_votes: updated_votes}
  end

  def apply(proposal, %AuroraGov.Event.ProposalExecuted{}) do
    %__MODULE__{proposal | proposal_status: :executing}
  end

  def apply(proposal, %AuroraGov.Event.ProposalConsumed{}) do
    %__MODULE__{proposal | proposal_status: :consumed}
  end

  def calculate_proposal_votes(%AuroraGov.Event.ProposalCreated{proposal_voters: proposal_voters}) do
    Enum.reduce(proposal_voters, %{}, fn {person_id, %{ou_id: ou_ids}}, acc ->
      vote = %Vote{
        vote_id: Ecto.ShortUUID.generate(),
        ou_id: ou_ids
      }

      Map.put(acc, person_id, vote)
    end)
  end

  # # Evento para consumir la propuesta
  # def apply(proposal, %AuroraGov.Event.ProposalConsumed{}) do
  #   %__MODULE__{proposal | proposal_status: :consumed}
  # end

  def get_proposal(proposal_id) do
    case AuroraGov.aggregate_state(__MODULE__, proposal_id) do
      %__MODULE__{proposal_id: nil} -> {:error, :proposal_not_exists}
      %__MODULE__{} = proposal -> {:proposal, proposal}
    end
  end

  # Comprueba si un person_id puede votar en la propuesta:
  # - la propuesta debe estar activa
  # - debe existir una entrada en proposal_votes para person_id
  # - el vote_value debe ser nil (pendiente)
  @spec can_vote?(t :: %__MODULE__{}, person_id :: any()) :: boolean()
  def can_vote?(%__MODULE__{proposal_status: :active, proposal_votes: votes}, person_id) do
    case Map.get(votes || %{}, person_id) do
      %Vote{vote_value: nil} -> true
      _ -> false
    end
  end

  def can_vote?(%__MODULE__{}, _person_id), do: false

  @spec can_vote?(proposal_id :: any(), person_id :: any()) :: boolean()
  def can_vote?(proposal_id, person_id) do
    case AuroraGov.aggregate_state(__MODULE__, proposal_id) do
      %__MODULE__{proposal_id: nil} -> false
      %__MODULE__{} = proposal -> can_vote?(proposal, person_id)
    end
  end

  def execute(
        %__MODULE__{proposal_status: :active} = proposal,
        %AuroraGov.Command.ExecuteProposal{}
      ) do
    # 1. Validaciones (mantenemos tu lógica)
    with :ok <- validate_proposal_score(proposal) do
      # 2. Retornamos el evento (NO hacemos dispatch aquí)
      %AuroraGov.Event.ProposalExecuted{
        proposal_id: proposal.proposal_id,
        proposal_power_id: proposal.proposal_power_id,
        proposal_power_data: proposal.proposal_power_data
      }
    end
  end

  def execute(
        %__MODULE__{proposal_status: :executing} = proposal,
        %AuroraGov.Command.ConsumeProposal{} = command
      ) do
    %AuroraGov.Event.ProposalConsumed{
      proposal_id: proposal.proposal_id,
      proposal_execution_result: command.proposal_execution_result,
      proposal_execution_error: command.proposal_execution_error
    }
  end

  # Bloqueamos cualquier intento si ya no es activa
  def execute(%__MODULE__{}, %AuroraGov.Command.ExecuteProposal{}),
    do: {:error, :proposal_invalid_status}

  def execute(%__MODULE__{}, %AuroraGov.Command.ConsumeProposal{}),
    do: {:error, :proposal_invalid_status}

  # Aplicamos el cambio de estado

  defp validate_proposal_score(%__MODULE__{} = proposal) do
    Logger.debug("[#{__MODULE__}] #{inspect(proposal)}")
    :ok
  end
end
