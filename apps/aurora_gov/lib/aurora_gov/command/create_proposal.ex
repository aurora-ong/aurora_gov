defmodule AuroraGov.Command.CreateProposal do
  use Commanded.Command,
    proposal_id: :string,
    proposal_title: :string,
    proposal_description: :string,
    proposal_ou_origin: :string,
    proposal_ou_end: :string,
    proposal_power: :string,
    proposal_power_data: :string

  def handle_validate(changeset) do
    changeset
    |> validate_required([:proposal_title, :proposal_description, :proposal_ou_origin, :proposal_ou_end, :proposal_power, :proposal_power_data])
  end
end
