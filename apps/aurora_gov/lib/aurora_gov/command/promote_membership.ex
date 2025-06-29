defmodule AuroraGov.Command.PromoteMembership do
  use AuroraGov.Command,
    gov_power: [
      id: "org.membership.promote",
      name: "Promover membresía",
      description: "Promueve a un miembro hacía un estamento superior"
    ],
    fields: [
      ou_id: [command_type: :string, label: "Unidad Organizacional", form_type: :text, field_type: :user],
      membership_id: [
        command_type: :string,
        label: "Identificador membresía",
        description: "Identificador de la membresia a promover",
        form_type: :text,
        field_type: :user
      ]
    ]

  def handle_validate(changeset) do
    changeset
    |> validate_required([:ou_id, :membership_id])
  end
end
