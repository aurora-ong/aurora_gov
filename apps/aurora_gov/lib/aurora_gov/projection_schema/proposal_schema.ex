defmodule AuroraGov.Projector.Model.Proposal do
  use Ecto.Schema

  @primary_key {:proposal_id, :string, autogenerate: false}
  schema "proposal_table" do
    field :proposal_title, :string
    field :proposal_description, :string

    belongs_to :proposal_ou_start, AuroraGov.Projector.Model.OU,
      foreign_key: :proposal_ou_start_id,
      type: :string,
      references: :ou_id

    belongs_to :proposal_ou_end, AuroraGov.Projector.Model.OU,
      foreign_key: :proposal_ou_end_id,
      type: :string,
      references: :ou_id

    belongs_to :proposal_owner, AuroraGov.Projector.Model.Person,
      foreign_key: :proposal_owner_id,
      type: :string,
      references: :person_id

    field :proposal_power_id, :string
    field :proposal_power_data, :map
    field :proposal_status, Ecto.Enum, values: [:active, :consumed]
    embeds_many :proposal_votes, AuroraGov.Projector.Model.Proposal.Vote
    field :proposal_power_sensibility, :map

    field :created_at, :utc_datetime_usec
    field :updated_at, :utc_datetime_usec
    field :consumed_at, :utc_datetime_usec
  end


end
