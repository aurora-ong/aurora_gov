defmodule AuroraGov.Command.RenameOU do
  use AuroraGov.Command,
    gov_power: [
      id: "org.ou.rename",
      name: "Renombrar unidad organizacional",
      description: "Permite modificar el nombre visible de una unidad organizacional",
      category: :ou
    ],
    fields: [
      ou_id: [
        command_type: :string,
        label: "Unidad Organizacional",
        form_type: :text,
        source: {:context, :end_ou_id}
      ],
      ou_name: [
        command_type: :string,
        label: "Nuevo nombre de la unidad",
        description: "Ingrese el nuevo nombre visible de la unidad organizacional.",
        form_type: :text,
        source: :user
      ]
    ]

  @doc """
  Valida los datos necesarios para solicitar el cambio de nombre
  de una unidad organizacional.

  El `ou_id` no es ingresado por el usuario. Se obtiene del contexto
  de la OU actualmente seleccionada mediante `:end_ou_id`.

  El identificador de la OU permanece inmutable. Solamente se modifica
  su nombre visible (`ou_name`).
  """
  def handle_validate(changeset) do
    changeset
    |> validate_required([:ou_id, :ou_name])
    |> validate_length(:ou_name, min: 3, max: 30)
  end
end
