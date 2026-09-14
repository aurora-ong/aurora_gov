defmodule AuroraGov.Command.UpdateResource do
  use AuroraGov.Command,
    gov_power: [
      id: "org.resource.edit",
      name: "Editar Recurso",
      description: "Permite actualizar los metadatos (nombre y descripcin) de un recurso emitido por esta unidad.",
      category: :ledger
    ],
    fields: [
      ou_id: [
        command_type: :string,
        source: {:context, :end_ou_id}
      ],
      resource_id: [
        command_type: :string,
        label: "Recurso a Editar",
        form_type: :local_resource_selector,
        source: :user
      ],
      name: [
        command_type: :string,
        label: "Nuevo Nombre",
        form_type: :text,
        source: :user
      ],
      description: [
        command_type: :string,
        label: "Nueva Descripcin",
        form_type: :textarea,
        source: :user
      ]
    ]

  def handle_validate(changeset, _opts \\ []) do
    changeset
    |> validate_required([:ou_id, :resource_id, :name])
  end
end
