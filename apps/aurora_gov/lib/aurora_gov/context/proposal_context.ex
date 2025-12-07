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
            Logger.info("#{__MODULE__} create_proposal error #{inspect(reason)}")
        end

      {:error, invalid_changeset} ->
        {:error, invalid_changeset}
    end
  end

  def consume_proposal(proposal_id) do
    changeset = AuroraGov.Command.ExecuteProposal.new(%{proposal_id: proposal_id})

    case Ecto.Changeset.apply_action(changeset, :create) do
      {:ok, command} ->
        case AuroraGov.dispatch(command,
               consistency: :strong,
               returning: :execution_result,
               wait_for: [AuroraGov.ProcessManagers.ProposalExecutor],
               timeout: 30_000
             ) do
          {:ok, result} ->
            {:ok, result}

          {:error, reason} ->
            Logger.info("#{__MODULE__} consume_proposal error #{inspect(reason)}")
        end

      {:error, invalid_changeset} ->
        {:error, invalid_changeset}
    end
  end

  def apply_proposal_vote(vote_attrs) do
    changeset = AuroraGov.Command.ApplyProposalVote.new(vote_attrs)

    IO.inspect(vote_attrs)

    case Ecto.Changeset.apply_action(changeset, :create) do
      {:ok, command} ->
        case AuroraGov.dispatch(command,
               consistency: :strong,
               returning: :execution_result
             ) do
          {:ok, result} ->
            {:ok, result}

          {:error, reason} ->
            Logger.info(reason, name: "#{__MODULE__} apply_proposal_vote error")
            {:error, reason}
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
      required_score = round(sens_value / 100 * total_voters)

      # Suma de votos emitidos (solo los que tienen valor distinto de nil)
      current_score =
        relevant_votes
        |> Enum.filter(& &1.vote_value)
        |> Enum.map(& &1.vote_value)
        |> Enum.sum()

      emitted_votes_count =
        relevant_votes
        |> Enum.filter(& &1.vote_value)
        |> length()

      Map.put(acc, ou_id, %{
        required_score: required_score,
        current_score: current_score,
        total_voters: total_voters,
        current_voters: emitted_votes_count
      })
    end)
  end

  def get_proposal_by_id(proposal_id) do
    Repo.one(
      Proposal
      |> where([p], p.proposal_id == ^proposal_id)
      |> preload([:proposal_ou_start, :proposal_ou_end, :proposal_owner])
    )
  end

  def get_person_vote_from_proposal(%Proposal{proposal_votes: votes}, person_id) do
    Enum.find(votes, fn vote -> vote.person_id == person_id end)
  end

  def can_proposal_execute?(proposal_id) do
    Logger.debug("[#{__MODULE__}] #{inspect(proposal_id)}")
    {:proposal, proposal} = AuroraGov.Aggregate.Proposal.get_proposal(proposal_id)

    AuroraGov.Aggregate.Proposal.validate_proposal_score(proposal)
  end
end
