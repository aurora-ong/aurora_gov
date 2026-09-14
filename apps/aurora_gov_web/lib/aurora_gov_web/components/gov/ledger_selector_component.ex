defmodule AuroraGov.Web.Components.SmartInputs.LedgerSelector do
  use AuroraGov.Web, :live_component
  alias AuroraGov.Context.LedgerContext

  def update(assigns, socket) do
    ou_id = assigns[:ou_id]
    resource_id = assigns[:resource_id]

    ledgers = if ou_id do
      LedgerContext.list_ledgers_by_ou(ou_id)
      |> Enum.concat(LedgerContext.list_external_ledgers())
      |> Enum.filter(fn a -> is_nil(resource_id) or resource_id == "" or a.resource_id == resource_id end)
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
          <option value={ledger.ledger_id} selected={to_string(@field.value) == to_string(ledger.ledger_id)}>
            {ledger.name || ledger.ledger_id} (Balance: {ledger.balance})
          </option>
        <% end %>
      </select>
      
      <%= for err <- @errors || [] do %>
        <span class="text-xs text-red-500 mt-2 block font-bold">
          <i class="fa-solid fa-circle-exclamation mr-1"></i>{err}
        </span>
      <% end %>
    </div>
    """
  end
end
