defmodule AuroraGov.Command.PromoteMembership do
  use AuroraGov.Command,
    gov_power: [
      id: "org.membership.promote",
      name: "Promover membresía",
      description: "Promueve a un miembro hacía un estamento superior"
    ],
    fields: [
      ou_id: [command_type: :string, label: "Unidad Organizacional", form_type: :text, field_type: :user],
      person_id: [
        command_type: :string,
        label: "Identificador persona",
        description: "Identificador de la persona a promover",
        form_type: :text,
        field_type: :user
      ]
    ]

  def handle_validate(changeset) do
    changeset
    |> validate_required([:ou_id, :person_id])
  end
end
