defmodule AuroraGov.Command.CreateProposal do
  use Commanded.Command,
    proposal_id: :string,
    proposal_title: :string,
    proposal_description: :string,
    proposal_ou_origin: :string,
    proposal_person_id: :string,
    proposal_ou_end: :string,
    proposal_power_id: :string,
    proposal_power_data: :map

  # def handle_validate(changeset) do
  #   IO.inspect(inspect(changeset), label: "QQ", pretty: true, limit: :infinity)
  #   changeset
  # end

  def handle_validate_step(params, 0) do
    AuroraGov.Command.CreateProposal.new(params)
    |> validate_required([
      :proposal_ou_origin,
      :proposal_ou_end,
      :proposal_power_id
    ])
  end

  def handle_validate_step(params, 1) do
    AuroraGov.Command.CreateProposal.new(params)
    |> validate_required([
      :proposal_title,
      :proposal_description
    ])
    |> validate_length(:proposal_title, min: 5)
    |> validate_length(:proposal_description, min: 10)
  end

  def handle_validate_create(params) do
    AuroraGov.Command.CreateProposal.new(params)
    |> validate_required([
      :proposal_person_id,
      :proposal_title,
      :proposal_description,
      :proposal_ou_origin,
      :proposal_ou_end,
      :proposal_power_id
    ])
    |> validate_length(:proposal_title, min: 5)
    |> validate_length(:proposal_description, min: 10)
    |> put_change(:proposal_id, Ecto.UUID.generate)
  end
end
