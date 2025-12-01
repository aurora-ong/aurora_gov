defmodule AuroraGov.Command.ExecuteProposal do
  use Commanded.Command,
    proposal_id: :string

  def handle_validate(changeset) do
    changeset
    |> validate_required([:proposal_id])
  end
end
