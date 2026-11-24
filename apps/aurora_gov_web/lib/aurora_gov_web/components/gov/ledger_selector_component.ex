defmodule AuroraGov.Web.Components.SmartInputs.LedgerSelector do
  use AuroraGov.Web, :live_component
  alias AuroraGov.Context.LedgerContext

  def update(assigns, socket) do
    ou_id = assigns[:ou_id]
    resource_id = assigns[:resource_id]

    ledgers =
      if ou_id do
        LedgerContext.list_ledgers_by_ou(ou_id)
        |> Enum.concat(LedgerContext.list_external_ledgers())
        |> Enum.filter(fn a ->
          is_nil(resource_id) or resource_id == "" or a.resource_id == resource_id
        end)
      else
        []
      end

    socket =
      socket
      |> assign(assigns)
      |> assign(:ledgers, ledgers)
      |> assign(:errors, Enum.map(assigns.field.errors, fn {msg, _} -> msg end))

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div>
      <label class="block text-sm font-semibold text-gray-700 mb-2">{@label}</label>
      <select
        name={@field.name}
        class="w-full text-sm border-gray-200 rounded-lg focus:ring-aurora_orange focus:border-aurora_orange"
      >
        <option value="">Selecciona una cuenta...</option>

        <%= for ledger <- @ledgers do %>
          <option
            value={ledger.ledger_id}
            selected={to_string(@field.value) == to_string(ledger.ledger_id)}
          >
            {ledger.name} ({ledger.ledger_id})
          </option>
        <% end %>
      </select> <% selected_ledger =
        Enum.find(@ledgers, &(to_string(&1.ledger_id) == to_string(@field.value))) %>
      <%= if selected_ledger do %>
        <% resource_name =
          if Ecto.assoc_loaded?(selected_ledger.resource) and selected_ledger.resource,
            do: selected_ledger.resource.name,
            else: nil %> <% resource_unit =
          if Ecto.assoc_loaded?(selected_ledger.resource) and selected_ledger.resource,
            do: selected_ledger.resource.unit_of_measure,
            else: "" %>
        <div class="mt-2 p-2.5 bg-gray-50 rounded-lg border border-gray-200 flex flex-wrap items-center justify-between gap-2 text-xs">
          <div class="flex items-center gap-3">
            <.resource_id_badge id={selected_ledger.resource_id} size="sm" />
            <span class="text-gray-500 border-l border-gray-200 pl-3">
              <span class="font-medium text-gray-700 capitalize">{selected_ledger.ledger_type}</span>
            </span>
          </div>

          <div class="flex items-center gap-3">
            <span class="text-gray-700">
              Saldo disponible:
              <span class="font-bold text-gray-900">{selected_ledger.balance} {resource_unit}</span>
            </span>
          </div>
        </div>
      <% end %>

      <%= for err <- @errors || [] do %>
        <span class="text-xs text-red-500 mt-2 block font-bold">
          <i class="fa-solid fa-circle-exclamation mr-1"></i>{err}
        </span>
      <% end %>
    </div>
    """
  end
end
