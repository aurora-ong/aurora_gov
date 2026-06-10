defmodule AuroraGov.Projector.Model.Proposal.Vote do
  use Ecto.Schema

  @primary_key false
  embedded_schema do
    field :person_id, :string
    field :vote_ou, {:array, :string}
    field :vote_value, :integer
    field :vote_type, Ecto.Enum, values: [:direct, :delegated]
    field :vote_comment, :string
    field :updated_at, :utc_datetime_usec
  end
end
