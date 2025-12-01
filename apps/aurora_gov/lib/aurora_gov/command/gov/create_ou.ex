defmodule AuroraGov.Command.CreateOU do
  use AuroraGov.Command,
    gov_power: [
      id: "org.ou.create",
      name: "Crear unidad organizacional",
      description: "Permite crear una unidad organizacional"
    ],
    fields: [
      ou_id: [
        command_type: :string,
        label: "Identificador de la unidad",
        form_type: :text,
        field_type: :user,
        description: "Identificador único de la unidad organizacional."
      ],
      ou_name: [
        command_type: :string,
        label: "Nombre de la unidad",
        form_type: :text,
        field_type: :user
      ],
      ou_goal: [
        command_type: :string,
        label: "Objetivo de la unidad",
        form_type: :text,
        field_type: :user
      ],
      ou_description: [
        command_type: :string,
        label: "Descripción de la unidad",
        form_type: :textarea,
        field_type: :user
      ]
    ]

  def handle_validate(changeset) do
    changeset
    |> validate_required([:ou_name, :ou_goal, :ou_description])
  end
end
