defmodule AuroraGov.Event.MembershipExpelled do
  use Ecto.Schema

  @derive Jason.Encoder
  @primary_key false

  embedded_schema do
    field :person_id, :string
    field :ou_id, :string
  end

  def new(params) do
    %__MODULE__{}
    |> Ecto.Changeset.cast(params, [
      :person_id,
      :ou_id
    ])
    |> Ecto.Changeset.apply_action!(:insert)
  end
end
