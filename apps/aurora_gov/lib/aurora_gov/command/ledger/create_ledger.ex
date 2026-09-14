defmodule AuroraGov.Command.CreateLedger do
  use AuroraGov.Command,
    gov_power: [
      id: "org.ledger.create",
      name: "Aperturar Cuenta",
      description: "Permite crear una nueva cuenta contable para la unidad organizacional.",
      category: :ledger
    ],
    fields: [
      ledger_id: [
        command_type: :string,
        source: :auto
      ],
      owner_id: [
        command_type: :string, 
        source: {:context, :end_ou_id}
      ],
      owner_type: [
        command_type: :string, 
        source: :auto
      ],
      ledger_type: [
        command_type: :string,
        label: "Naturaleza de la Cuenta",
        form_type: :select,
        options: [
          {"Activo (Asset) - Saldo positivo", "asset"}, 
          {"Pasivo (Liability) - Saldo deudor", "liability"}, 
          {"Patrimonio (Equity) - Capital", "equity"}, 
          {"Externa (Mundo Real)", "external"}
        ],
        source: :user
      ],
      resource_id: [
        command_type: :string,
        label: "Recurso Asociado",
        form_type: :resource_selector,
        source: :user
      ],
      name: [
        command_type: :string,
        label: "Nombre de la Cuenta",
        form_type: :text,
        source: :user
      ],
      description: [
        command_type: :string,
        label: "Descripción de la Cuenta",
        form_type: :textarea,
        source: :user
      ]
    ]

  def handle_validate(changeset, _opts \\ []) do
    changeset
    |> put_change(:owner_type, "ou")
    |> validate_required([:owner_id, :owner_type, :ledger_type, :resource_id, :name])
    |> validate_length(:name, min: 3, max: 100)
    |> build_ledger_id()
  end

  defp build_ledger_id(changeset) do
    case get_field(changeset, :ledger_id) do
      nil -> put_change(changeset, :ledger_id, generate_10_digit_id())
      _ -> changeset
    end
  end

  defp generate_10_digit_id do
    to_string(Enum.random(1_000_000_000..9_999_999_999))
  end
end
