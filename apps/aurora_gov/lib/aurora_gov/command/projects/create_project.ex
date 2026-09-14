defmodule AuroraGov.Command.CreateProject do
  use AuroraGov.Command,
    gov_power: [
      id: "org.project.create",
      name: "Crear proyecto",
      description: "Permite crear un proyecto en la unidad organizacional",
      category: :work
    ],
    fields: [
      ou_id: [
        command_type: :string,
        source: {:context, :end_ou_id}
      ],
      project_id: [
        command_type: :string,
        source: :auto
      ],
      name: [
        command_type: :string,
        label: "Nombre del proyecto",
        form_type: :text,
        source: :user
      ],
      description: [
        command_type: :string,
        label: "Descripción",
        form_type: :textarea,
        source: :user
      ]
    ]

  def handle_validate(changeset, _opts) do
    changeset
    |> validate_required([:ou_id, :name, :description])
    |> validate_length(:name, min: 3, max: 100)
    |> build_project_id()
  end

  defp build_project_id(changeset) do
    case get_field(changeset, :project_id) do
      nil ->
        put_change(changeset, :project_id, Ecto.ShortUUID.generate())
      _ ->
        changeset
    end
  end
end
