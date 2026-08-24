defmodule AuroraGov.Command.UpdateOUGoal do
  use AuroraGov.Command,
    gov_power: [
      id: "org.ou.update_goal",
      name: "Actualizar propósito de la unidad",
      description: "Permite modificar el objetivo y la descripción de una unidad organizacional",
      category: :ou
    ],
    fields: [
      ou_id: [
        command_type: :string,
        label: "Unidad Organizacional",
        form_type: :text,
        source: {:context, :end_ou_id}
      ],
      ou_goal: [
        command_type: :string,
        label: "Nuevo objetivo de la unidad",
        description: "Defina el objetivo principal de la unidad organizacional.",
        form_type: :text,
        source: :user
      ]
    ]

  @doc """
  Valida los datos necesarios para modificar el objetivo de una
  unidad organizacional.

  La OU sobre la que se realizará la operación se obtiene del contexto
  actual. El usuario solamente proporciona el nuevo objetivo
  """
  def handle_validate(changeset) do
    changeset
    |> validate_required([:ou_id, :ou_goal])
  end
end
