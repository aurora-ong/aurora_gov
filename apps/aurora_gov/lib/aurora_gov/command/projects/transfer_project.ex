defmodule AuroraGov.Command.TransferProject do
  use AuroraGov.Command,
    gov_power: [
      id: "org.project.transfer",
      name: "Transferir proyecto",
      description: "Permite transferir un proyecto a otra unidad organizacional",
      category: :work
    ],
    fields: [
      ou_id: [
        command_type: :string,
        source: {:context, :end_ou_id}
      ],
      project_id: [
        command_type: :string,
        label: "Proyecto",
        form_type: :project_search,
        source: :user
      ],
      destination_ou_id: [
        command_type: :string,
        label: "Unidad organizacional de destino",
        form_type: :ou_search,
        source: :user
      ]
    ]

  def handle_validate(changeset, _opts) do
    changeset
    |> validate_required([:ou_id, :project_id, :destination_ou_id])
  end
end
