defmodule AuroraGov.Command.CreateOU do
  use AuroraGov.Command,
    gov_power: [
      id: "org.ou.create",
      name: "Crear unidad organizacional",
      description: "Permite crear una unidad organizacional"
    ],
    fields: [
      ou_id: [
        type: :string,
        label: "Identificador de la unidad",
        form_type: :text,
        visible?: true,
        description: "Identificador único de la unidad organizacional."
      ],
      ou_name: [type: :string, label: "Nombre de la unidad", form_type: :text, visible?: true],
      ou_goal: [type: :string, label: "Objetivo de la unidad", form_type: :text, visible?: true],
      ou_description: [
        type: :string,
        label: "Descripción de la unidad",
        form_type: :textarea,
        visible?: true
      ]
    ]

  def handle_validate(changeset) do
    changeset
    # |> put_change(:person_id, Ecto.ShortUUID.generate())
    |> validate_required([:ou_name, :ou_goal, :ou_description])
  end
end
