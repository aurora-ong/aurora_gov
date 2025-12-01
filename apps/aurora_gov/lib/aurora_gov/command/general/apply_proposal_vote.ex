defmodule AuroraGov.Command.ApplyProposalVote do
  use Commanded.Command,
    proposal_id: :string,
    person_id: :string,
    vote_value: :integer,
    vote_comment: :string,
    vote_type: :string

  def handle_validate(changeset) do
    changeset
    |> validate_required([:proposal_id, :person_id, :vote_value, :vote_comment, :vote_type])
    |> validate_number(:vote_value, greater_than_or_equal_to: -1, less_than_or_equal_to: 1)
  end
end
