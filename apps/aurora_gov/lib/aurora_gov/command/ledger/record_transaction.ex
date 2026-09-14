defmodule AuroraGov.Command.RecordTransaction do
  use AuroraGov.Command,
    gov_power: [
      id: "org.transaction.record",
      name: "Registrar Transacción",
      description: "Permite asentar una transferencia simple entre dos cuentas.",
      category: :ledger
    ],
    fields: [
      transaction_id: [command_type: :string, source: :auto],
      timestamp: [command_type: :utc_datetime, source: :auto],
      origin_ledger_id: [command_type: :string, label: "Cuenta de Origen", form_type: :ledger_selector_origin, source: :user],
      destination_ledger_id: [command_type: :string, label: "Cuenta de Destino", form_type: :ledger_selector_end, source: :user],
      amount: [command_type: :decimal, label: "Monto a Transferir", form_type: :number, source: :user],
      description: [command_type: :string, label: "Descripción", form_type: :text, source: :user],
      reference_id: [command_type: :string, label: "ID de Referencia Externa", form_type: :text, source: :user],
      reference_type: [command_type: :string, source: :auto]
    ]

  def handle_validate(changeset) do
    changeset
    |> put_change(:transaction_id, Ecto.UUID.generate())
    |> put_change(:timestamp, DateTime.utc_now())
    |> put_change(:reference_type, "manual")
    |> validate_required([:origin_ledger_id, :destination_ledger_id, :amount])
  end
end
