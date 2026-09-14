defmodule AuroraGov.Web.Components.SmartInputs.LedgerEntriesEditor do
  use AuroraGov.Web, :live_component
  use Phoenix.Component
  alias AuroraGov.Context.LedgerContext

  @impl true
  def update(assigns, socket) do
    entries =
      case assigns.field.value do
        nil -> []
        "" -> []
        list when is_list(list) -> list
        map when is_map(map) -> 
          # Forms submit maps with integer string keys ("0", "1")
          map 
          |> Enum.sort_by(fn {k, _} -> String.to_integer(k) end) 
          |> Enum.map(fn {_, v} -> v end)
        _ -> []
      end

    ou_id = assigns.app_context.current_ou_id
    ledgers = LedgerContext.list_ledgers_by_ou(ou_id)
    
    socket =
      socket
      |> assign(assigns)
      |> assign(:entries, entries)
      |> assign(:ledgers, ledgers)
      |> assign_new(:new_ledger_id, fn -> "" end)
      |> assign_new(:new_amount, fn -> "" end)
      |> assign_new(:new_description, fn -> "" end)
      |> assign(:errors, Enum.map(assigns.field.errors, fn {msg, _} -> msg end))

    {:ok, socket}
  end
  
  @impl true
  def render(assigns) do
    ~H"""
    <div class="w-full bg-white border border-gray-200 rounded-xl p-4">
      <label class="block text-sm font-semibold text-gray-700 mb-4">{@label}</label>

      <!-- Hidden inputs for form submission -->
      <%= for {entry, idx} <- Enum.with_index(@entries) do %>
        <input type="hidden" name={"#{@field.name}[#{idx}][ledger_id]"} value={entry["ledger_id"] || entry[:ledger_id]} />
        <input type="hidden" name={"#{@field.name}[#{idx}][resource_id]"} value={entry["resource_id"] || entry[:resource_id]} />
        <input type="hidden" name={"#{@field.name}[#{idx}][amount]"} value={entry["amount"] || entry[:amount]} />
        <input type="hidden" name={"#{@field.name}[#{idx}][description]"} value={entry["description"] || entry[:description]} />
      <% end %>

      <!-- List of current entries -->
      <div class="space-y-3 mb-6">
        <%= for {entry, idx} <- Enum.with_index(@entries) do %>
          <div class="flex items-center justify-between p-3 bg-gray-50 border border-gray-100 rounded-lg">
            <div class="flex-1">
              <div class="flex items-center gap-2">
                <span class="font-mono text-xs text-gray-500" title={entry["ledger_id"] || entry[:ledger_id]}>Cuenta</span>
                <span class="font-bold text-sm text-gray-800">{entry["description"] || entry[:description]}</span>
              </div>
            </div>
            <div class={"font-bold px-3 py-1 rounded-md text-sm " <> if(is_binary(entry["amount"] || entry[:amount]) && String.starts_with?(entry["amount"] || entry[:amount], "-"), do: "bg-red-100 text-red-700", else: "bg-emerald-100 text-emerald-700")}>
              {entry["amount"] || entry[:amount]} <span class="text-xs uppercase ml-1">{entry["resource_id"] || entry[:resource_id]}</span>
            </div>
            <button type="button" phx-click="remove_entry" phx-value-idx={idx} phx-target={@myself} class="ml-4 text-gray-400 hover:text-red-500">
              <i class="fa-solid fa-trash"></i>
            </button>
          </div>
        <% end %>
        <%= if Enum.empty?(@entries) do %>
          <div class="text-center p-6 text-sm text-gray-400 border-2 border-dashed border-gray-100 rounded-lg">
            Aún no hay asientos contables. Agrega uno abajo.
          </div>
        <% end %>
      </div>

      <!-- Add new entry form -->
      <div class="bg-blue-50/50 border border-blue-100 rounded-xl p-4">
        <h4 class="text-xs font-bold text-blue-800 uppercase tracking-wide mb-3">Agregar Movimiento</h4>
        <form phx-change="update_new_entry" phx-submit="add_entry" phx-target={@myself}>
          <div class="grid grid-cols-12 gap-3">
            <div class="col-span-12 md:col-span-6">
              <label class="block text-xs text-gray-500 mb-1">Cuenta</label>
              <select
                name="new_ledger_id"
                class="w-full text-sm border-gray-200 rounded-lg focus:ring-aurora_orange focus:border-aurora_orange"
              >
                <option value="">Selecciona una cuenta...</option>
                <%= for acc <- @ledgers do %>
                  <option value={acc.ledger_id} selected={@new_ledger_id == acc.ledger_id}>
                    {acc.name || acc.ledger_id} ({acc.resource_id})
                  </option>
                <% end %>
              </select>
            </div>
            <div class="col-span-6 md:col-span-6">
              <label class="block text-xs text-gray-500 mb-1">Monto (ej: 100 o -100)</label>
              <input
                type="number"
                step="0.01"
                name="new_amount"
                value={@new_amount}
                class="w-full text-sm border-gray-200 rounded-lg focus:ring-aurora_orange focus:border-aurora_orange"
              />
            </div>
            
            <div class="col-span-12 md:col-span-8">
              <label class="block text-xs text-gray-500 mb-1">Descripción</label>
              <input
                type="text"
                name="new_description"
                value={@new_description}
                placeholder="Ej: Pago por materiales..."
                class="w-full text-sm border-gray-200 rounded-lg focus:ring-aurora_orange focus:border-aurora_orange"
              />
            </div>
            <div class="col-span-12 md:col-span-4 flex items-end">
               <button
                  type="submit"
                  class="w-full py-2 bg-aurora_orange text-white text-sm font-bold rounded-lg hover:bg-orange-600 transition disabled:opacity-50"
                  disabled={@new_ledger_id == "" or @new_amount == ""}
               >
                 <i class="fa-solid fa-plus mr-1"></i> Añadir
               </button>
            </div>
          </div>
        </form>
      </div>
      
      <!-- Balance Check -->
      <%
        balances = 
          @entries 
          |> Enum.reduce(%{}, fn e, acc ->
             res = e["resource_id"] || e[:resource_id]
             
             # Handle potential decimal parsing issues gracefully
             amt_str = to_string(e["amount"] || e[:amount])
             amt = case Decimal.parse(amt_str) do
               {d, _} -> d
               :error -> Decimal.new("0.0")
             end
             
             Map.update(acc, res, amt, &Decimal.add(&1, amt))
          end)
          
        unbalanced = Enum.filter(balances, fn {_, sum} -> not Decimal.eq?(sum, Decimal.new("0.0")) end)
      %>
      
      <%= if length(@entries) > 0 do %>
        <div class={"mt-4 p-3 rounded-lg flex items-center gap-2 text-sm " <> if(Enum.empty?(unbalanced), do: "bg-emerald-50 text-emerald-700 border border-emerald-100", else: "bg-red-50 text-red-700 border border-red-100")}>
          <%= if Enum.empty?(unbalanced) do %>
            <i class="fa-solid fa-check-circle"></i>
            <div>
               <strong>Balance OK.</strong> La transacción cuadra perfectamente.
            </div>
          <% else %>
            <i class="fa-solid fa-triangle-exclamation"></i>
            <div>
              <strong>¡Desbalance!</strong> La partida doble no suma cero:
              <ul class="ml-4 list-disc text-xs mt-1">
                <%= for {res, sum} <- unbalanced do %>
                  <li>{res}: {sum}</li>
                <% end %>
              </ul>
            </div>
          <% end %>
        </div>
      <% end %>
      
      <!-- Errores Ecto -->
      <%= for err <- @errors || [] do %>
        <span class="text-xs text-red-500 mt-2 block font-bold">
          <i class="fa-solid fa-circle-exclamation mr-1"></i>{err}
        </span>
      <% end %>
    </div>
    """
  end

  @impl true
  def handle_event("update_new_entry", params, socket) do
    {:noreply,
     socket
     |> assign(:new_ledger_id, params["new_ledger_id"] || "")
     |> assign(:new_amount, params["new_amount"] || "")
     |> assign(:new_description, params["new_description"] || "")}
  end
  
  @impl true
  def handle_event("add_entry", _params, socket) do
    acc_id = socket.assigns.new_ledger_id
    amt = socket.assigns.new_amount
    desc = socket.assigns.new_description
    
    if acc_id != "" and amt != "" do
      ledger = Enum.find(socket.assigns.ledgers, &(&1.ledger_id == acc_id))
      
      new_entry = %{
        "ledger_id" => acc_id,
        "resource_id" => ledger.resource_id,
        "amount" => amt,
        "description" => desc
      }
      
      updated_entries = socket.assigns.entries ++ [new_entry]
      notify_parent(updated_entries, socket)

      {:noreply, assign(socket, entries: updated_entries, new_amount: "", new_description: "")}
    else
      {:noreply, socket}
    end
  end
  
  @impl true
  def handle_event("remove_entry", %{"idx" => idx}, socket) do
    idx_int = String.to_integer(idx)
    updated_entries = List.delete_at(socket.assigns.entries, idx_int)
    
    notify_parent(updated_entries, socket)

    {:noreply, assign(socket, :entries, updated_entries)}
  end
  
  defp notify_parent(updated_entries, socket) do
    parent_module = socket.assigns[:parent_module] || AuroraGov.Web.Live.Panel.ProposalCreate
    parent_id = socket.assigns[:parent_id] || "modal-proposal_create"

    Phoenix.LiveView.send_update(
      parent_module,
      id: parent_id,
      info: {:ledger_entries_updated, socket.assigns.field.field, updated_entries}
    )
  end
end
