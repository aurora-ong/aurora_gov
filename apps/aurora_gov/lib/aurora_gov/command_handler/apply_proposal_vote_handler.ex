defmodule AuroraGov.CommandHandler.ApplyProposalVoteHandler do
  @behaviour Commanded.Commands.Handler
  alias AuroraGov.Aggregate.{Proposal}
  alias AuroraGov.Command.ApplyProposalVote
  alias AuroraGov.Event.VoteEmited
  require Logger

  def handle(
        %Proposal{} = proposal,
        %ApplyProposalVote{
          proposal_id: proposal_id,
          person_id: person_id,
          vote_value: vote_value,
          vote_comment: vote_comment,
          vote_type: vote_type
        }
      ) do
    with :active <- proposal.proposal_status || :inactive do

      %VoteEmited{
        proposal_id: proposal_id,
        person_id: person_id,
        vote_id: Ecto.ShortUUID.generate(),
        vote_value: vote_value,
        vote_comment: vote_comment,
        vote_type: vote_type
      }
    else
      {:error, _error} = error ->
        error

      error ->
        Logger.error("#{__MODULE__} Error inesperado #{inspect(error)}")
        {:error, :unexpected_error}
    end
  end

  def handle(%Proposal{proposal_id: nil}, %ApplyProposalVote{}) do
    {:error, :proposal_not_exists}
  end
end
