defmodule AuroraGov.Context.ProposalContext do
  require Logger

  alias AuroraGov.Projector.Repo
  alias AuroraGov.Projector.Model.Proposal
  import Ecto.Query

  def create_proposal(proposal_attrs) do
    changeset = AuroraGov.Command.CreateProposal.handle_validate_create(proposal_attrs)

    case Ecto.Changeset.apply_action(changeset, :create) do
      {:ok, command} ->
        case AuroraGov.dispatch(command, consistency: :strong, returning: :execution_result) do
          {:ok, result} ->
            {:ok, result}

          {:error, reason} ->
            Logger.info(reason, name: "#{__MODULE__} create_proposal error")
        end

      {:error, invalid_changeset} ->
        {:error, invalid_changeset}
    end
  end

  def list_proposals(params \\ %{}) do
    q =
      Proposal
      |> order_by(desc: :created_at)
      |> preload([:proposal_ou_start, :proposal_ou_end, :proposal_owner])

    {:ok, r} = Flop.validate_and_run(q, params)
    r
  end

  def calculate_voting_status(%Proposal{
        proposal_power_sensibility: sens_map,
        proposal_votes: votes
      }) do
    Enum.reduce(sens_map, %{}, fn {ou_id, sens_value}, acc ->
      # Votos que incluyen este ou_id
      relevant_votes =
        Enum.filter(votes, fn %Proposal.Vote{vote_ou: ou_ids} -> ou_id in ou_ids end)

      total_voters = length(relevant_votes)
      required_score = sens_value * total_voters

      # Suma de votos emitidos (solo los que tienen valor distinto de nil)
      current_score =
        relevant_votes
        |> Enum.filter(& &1.vote_value)
        |> Enum.map(& &1.vote_value)
        |> Enum.sum()

      Map.put(acc, ou_id, %{
        required_score: required_score,
        current_score: current_score,
        total_voters: total_voters
      })
    end)
  end

  def get_proposal_by_id(proposal_id) do
    case Repo.one(
           Proposal
           |> where([p], p.proposal_id == ^proposal_id)
           |> preload([:proposal_ou_start, :proposal_ou_end, :proposal_owner])
         ) do
      nil -> {:error, :not_found}
      proposal -> {:ok, proposal}
    end
  end
end
