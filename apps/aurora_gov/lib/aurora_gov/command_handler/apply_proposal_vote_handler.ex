defmodule AuroraGov.CommandHandler.ApplyProposalVoteHandler do
  @behaviour Commanded.Commands.Handler
  alias AuroraGov.Aggregate.{OU, Person, Proposal}
  alias AuroraGov.Command.ApplyProposalVote
  alias AuroraGov.Event.VoteEmited

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
      IO.inspect(proposal, label: "Proposal")

      %VoteEmited{
        proposal_id: proposal_id,
        person_id: person_id,
        vote_id: Ecto.ShortUUID.generate(),
        vote_value: vote_value,
        vote_comment: vote_comment,
        vote_type: vote_type
      }
    else
      {:error, :ou_not_exists} -> {:error, :ou_origin_not_exists}
      :inactive -> {:error, :ou_not_active}
      {:error, :person_not_exists} -> {:error, :person_not_exists}
      {:error, :membership_not_found} -> {:error, :person_not_member_of_ou}
      false -> {:error, :person_not_regular_or_senior}
      {:error, :ou_not_exists} -> {:error, :ou_end_not_exists}
    end
  end

  def handle(%Proposal{proposal_id: nil}, %ApplyProposalVote{}) do
    {:error, :proposal_not_exists}
  end
end
