defmodule AuroraGov.Command.ConsumeProposal do
  use Commanded.Command,
    proposal_id: :string,
    proposal_execution_result: :string,
    proposal_execution_error: :string

  def handle_validate(changeset) do
    changeset
    |> validate_required([:proposal_id, :proposal_execution_result])
  end
end
