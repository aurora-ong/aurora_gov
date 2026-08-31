defmodule AuroraGov.Command.ExpelMembership do
  use AuroraGov.Command,
    gov_power: [
      id: "org.membership.expel",
      name: "Expulsar miembro",
      description:
        "Expulsa a un miembro de esta unidad y de todas las subunidades descendientes a las que pertenezca.",
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
        description: "Identificador de la persona que se desea expulsar",
        form_type: :text,
        source: :user
      ]
    ]

  def handle_validate(changeset) do
    changeset
    |> validate_required([:person_id])
  end
end
