defmodule AuroraGov.Command.CreateProposal do
  use Commanded.Command,
    proposal_id: :string,
    proposal_title: :string,
    proposal_description: :string,
    proposal_ou_origin: :string,
    proposal_ou_end: :string,
    proposal_power: :string,
    proposal_power_data: :string

  # def handle_validate(changeset) do
  #   IO.inspect(inspect(changeset), label: "QQ", pretty: true, limit: :infinity)
  #   changeset
  # end

  def handle_validate_step(params, 0) do
    AuroraGov.Command.CreateProposal.new(params)
    |> validate_required([
      :proposal_ou_origin,
      :proposal_ou_end,
      :proposal_power
    ])
  end

  def handle_validate_step(params, 1) do
    AuroraGov.Command.CreateProposal.new(params)
    |> validate_required([
      :proposal_title,
      :proposal_description
    ])
    |> validate_length(:proposal_title, [min: 5])
    |> validate_length(:proposal_description, [min: 10])
  end
end
