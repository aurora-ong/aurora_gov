defmodule AuroraGov.Command.DowngradeMembership do
  use AuroraGov.Command,
    gov_power: [
      id: "org.membership.downgrade",
      name: "Degradar membresía",
      description: "Degrada a un miembro hacia un estamento inferior",
      category: :membership
    ],
    fields: [
      ou_id: [
        command_type: :string,
        label: "Unidad Organizacional",
        form_type: :text,
        source: {:context, :end_ou_id}
      ],
      person_id: [
        command_type: :string,
        label: "Identificador persona",
        description: "Identificador de la persona cuyo rango se desea bajar",
        form_type: :text,
        source: :user
      ]
    ]

  def handle_validate(changeset) do
    changeset
    |> validate_required([:person_id])
  end
end
