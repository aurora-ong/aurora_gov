defmodule AuroraGov.Aggregate.Proposal do
  defstruct [
    :proposal_id,
    :proposal_ou_id,
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

  @type status :: :active | :consumed

  defmodule Vote do
    defstruct [
      :person_id,
      # [ou_id]
      :ou_ids,
      # -1 | 0 | 1
      :vote_value
    ]
  end

  # Ejemplo de evento para registrar una propuesta
  def apply(_proposal, %AuroraGov.Event.ProposalCreated{
        proposal_id: proposal_id,
        proposal_ou_id: proposal_ou_id,
        proposal_owner_id: proposal_owner_id,
        proposal_power_id: proposal_power_id,
        proposal_power_data: proposal_power_data,
        proposal_power_sensibility: power_sensibility
      }) do
    %__MODULE__{
      proposal_id: proposal_id,
      proposal_ou_id: proposal_ou_id,
      proposal_owner_id: proposal_owner_id,
      proposal_power_id: proposal_power_id,
      proposal_power_data: proposal_power_data,
      proposal_status: :active,
      proposal_votes: %{},
      proposal_power_sensibility: power_sensibility
    }
  end

  # Ejemplo de evento para registrar un voto
  # def apply(%__MODULE__{votes: votes} = proposal, %AuroraGov.Event.ProposalVoted{
  #       person_id: person_id,
  #       ou_ids: ou_ids,
  #       vote_value: vote_value
  #     }) do
  #   updated_votes =
  #     Map.put(votes, person_id, %Vote{
  #       person_id: person_id,
  #       ou_ids: ou_ids,
  #       vote_value: vote_value
  #     })

  #   %__MODULE__{proposal | votes: updated_votes}
  # end

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
end
