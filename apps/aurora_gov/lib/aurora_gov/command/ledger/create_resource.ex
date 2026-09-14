defmodule AuroraGov.Command.CreateResource do
  use AuroraGov.Command,
    gov_power: [
      id: "org.resource.create",
      name: "Crear Recurso Contable",
      description: "Permite definir un nuevo recurso (fungible o no fungible) en el Ledger de la organización.",
      category: :ledger
    ],
    fields: [
      ou_id: [
        command_type: :string,
        label: "Unidad",
        form_type: :text,
        source: {:context, :end_ou_id}
      ],
      resource_id: [
        command_type: :string,
        label: "ID del Recurso (Ej. clp, usd, hh)",
        form_type: :text,
        source: :user
      ],
      name: [
        command_type: :string,
        label: "Nombre del Recurso",
        form_type: :text,
        source: :user
      ],
      description: [
        command_type: :string,
        label: "Descripción del Recurso",
        form_type: :textarea,
        source: :user
      ],
      unit_of_measure: [
        command_type: :string,
        label: "Unidad de Medida (Ej. $, Horas)",
        form_type: :text,
        source: :user
      ],
      is_fungible: [
        command_type: :boolean,
        label: "¿Es Fungible?",
        form_type: :checkbox,
        source: :user
      ]
    ]

  def handle_validate(changeset) do
    changeset
    |> validate_required([:resource_id, :name, :unit_of_measure])
    |> validate_format(:resource_id, ~r/^[a-z0-9_]+$/, message: "Solo puede contener minúsculas, números y guiones bajos")
  end
end
