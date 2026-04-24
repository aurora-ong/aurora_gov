defmodule AuroraGov.Event.MembershipPromoted do
  # 1. ¡ESTO ES OBLIGATORIO!
  use Ecto.Schema

  # 2. Esto es para que se pueda guardar en JSON
  @derive Jason.Encoder

  # 3. Importante: Los eventos no tienen ID de base de datos propio
  @primary_key false

  embedded_schema do
    field :person_id, :string
    field :ou_id, :string

    # Aquí defines el Enum para que haga la conversión automática String <-> Atom
    field :membership_rank, Ecto.Enum, values: [:junior, :senior, :regular, :formal]

    # Si tienes más campos, agrégalos aquí (ej: timestamps si los usas)
  end

  # 4. Constructor Helper (Opcional pero recomendado para Commanded)
  # Ayuda a crear el struct desde un mapa de claves string o atom
  def new(params) do
    %__MODULE__{}
    |> Ecto.Changeset.cast(params, [:person_id, :ou_id, :membership_rank])
    |> Ecto.Changeset.apply_action!(:insert)
  end
end
