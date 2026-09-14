defmodule AuroraGov.Command.RevokeMembership do
  use AuroraGov.Command,
    gov_power: [
      id: "org.membership.revoke",
      name: "Revocar membresia",
      description:
        "Revoca la membresia de un miembro de esta unidad (y en cascada)",
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
        description: "Identificador de la persona a la que se desea revocar",
        form_type: :text,
        source: :user
      ],
      reason: [
        command_type: :string,
        label: "Razon de la revocacion",
        description: "Motivo por el cual se revoca la membresia",
        form_type: :text,
        source: :user
      ]
    ]

  def handle_validate(changeset) do
    changeset
    |> validate_required([:person_id, :reason])
  end
end
