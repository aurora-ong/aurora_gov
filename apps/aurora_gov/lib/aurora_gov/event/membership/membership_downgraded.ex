defmodule AuroraGov.Event.MembershipDowngraded do
  use Ecto.Schema

  @derive Jason.Encoder
  @primary_key false

  embedded_schema do
    field :person_id, :string
    field :ou_id, :string

    # Se define el enum, para conversion automatica
    field :membership_rank, Ecto.Enum,
      values: [:junior, :senior, :regular, :formal]
  end

  # constructor
  def new(params) do
    %__MODULE__{}
    |> Ecto.Changeset.cast(params, [
      :person_id,
      :ou_id,
      :membership_rank
    ])
    |> Ecto.Changeset.apply_action!(:insert)
  end
end
