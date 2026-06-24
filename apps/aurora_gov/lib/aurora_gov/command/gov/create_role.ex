defmodule AuroraGov.Command.CreateRole do
  use AuroraGov.Command,
    gov_power: [
      id: "org.role.create",
      name: "Crear rol",
      description: "Permite crear un rol en la unidad organizacional",
      category: :role
    ],
    fields: [
      ou_id: [
        command_type: :string,
        label: "Unidad",
        form_type: :text,
        source: {:context, :end_ou_id}
      ],
      role_id: [
        command_type: :string,
        source: :auto
      ],
      role_name: [
        command_type: :string,
        label: "Nombre del rol",
        form_type: :text,
        source: :user
      ],
      role_description: [
        command_type: :string,
        label: "Descripción del rol",
        form_type: :textarea,
        source: :user
      ]
    ]

  def handle_validate(changeset) do
    changeset
    |> validate_required([:ou_id, :role_name, :role_description])
    |> generate_role_id()
  end

  defp generate_role_id(changeset) do
    case get_field(changeset, :role_id) do
      nil -> put_change(changeset, :role_id, Ecto.ShortUUID.generate())
      _ -> changeset
    end
  end
end
