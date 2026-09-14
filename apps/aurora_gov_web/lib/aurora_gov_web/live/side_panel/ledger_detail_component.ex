defmodule AuroraGov.Web.Live.Panel.Side.LedgerDetail do
  require Logger
  use AuroraGov.Web, :live_component
  alias AuroraGov.Context.LedgerContext

  @impl true
  def mount(socket) do
    {:ok, assign(socket, :ledger, nil) |> assign(:loading, true) |> assign(:active_tab, "general") |> assign(:entries, [])}
  end

  @impl true
  def handle_event("set_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, :active_tab, tab)}
  end

  @impl true
  def update(%{update: {type, _data}}, socket) do
    socket =
      if type in [:ledger_created, :transaction_recorded] do
        load_ledger_details(socket)
      else
        socket
      end

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(:app_context, assigns.app_context)
      |> assign(:ledger_id, assigns.ledger_id)
      |> load_ledger_details()

    {:ok, socket}
  end

  defp load_ledger_details(socket) do
    ledger_id = socket.assigns.ledger_id

    socket
    |> assign(:loading, true)
    |> start_async(:load_detail_data, fn ->
      ledger = LedgerContext.get_ledger(ledger_id)
      balance = LedgerContext.get_ledger_balance(ledger_id)
      entries = LedgerContext.list_ledger_entries(ledger_id)

      {ledger, balance, entries}
    end)
  end

  @impl true
  def handle_async(:load_detail_data, {:ok, {ledger, balance, entries}}, socket) do
    socket =
      socket
      |> assign(:loading, false)
      |> assign(:ledger, ledger)
      |> assign(:balance, balance)
      |> assign(:entries, entries)

    {:noreply, socket}
  end

  @impl true
  def handle_async(:load_detail_data, result, socket) do
    Logger.warning("Error loading ledger detail data: #{inspect(result)}")

    socket =
      socket
      |> assign(:loading, false)
      |> put_flash(:error, "No se pudieron cargar los detalles de la cuenta.")

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="w-full space-y-6">
      <%= if @loading or is_nil(@ledger) do %>
        <div class="flex items-center justify-center h-48">
          <.loading_spinner size="double_large" />
        </div>
      <% else %>
        <div>
          <div class="flex flex-col mb-4 gap-2">
            <h1 class="text-3xl font-bold text-gray-900 leading-tight">{@ledger.name}</h1>
            <div class="flex flex-wrap items-center gap-3">
              <.ledger_id_badge id={@ledger.ledger_id} />
              <.badge size="md" class={"bg-gray-100 " <> case to_string(@ledger.ledger_type) do
                "asset" -> "text-green-700 bg-green-50 border-green-200"
                "liability" -> "text-red-700 bg-red-50 border-red-200"
                "equity" -> "text-purple-700 bg-purple-50 border-purple-200"
                _ -> "text-gray-700"
              end}>
                <%= case to_string(@ledger.ledger_type) do %>
                  <% "asset" -> %>Activo
                  <% "liability" -> %>Pasivo
                  <% "equity" -> %>Patrimonio
                  <% _ -> %>Externa
                <% end %>
              </.badge>
            </div>
          </div>
        </div>

        <div class="border-b border-gray-200">
          <nav class="-mb-px flex space-x-6" aria-label="Tabs">
            <button
              phx-click="set_tab"
              phx-target={@myself}
              phx-value-tab="general"
              class={"whitespace-nowrap border-b-2 py-3 px-1 text-sm font-medium transition-colors " <>
                if @active_tab == "general",
                  do: "border-aurora_orange text-aurora_orange",
                  else: "border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700"}
            >
              <i class="fa-solid fa-circle-info mr-2"></i>Información General
            </button>
            <button
              phx-click="set_tab"
              phx-target={@myself}
              phx-value-tab="history"
              class={"whitespace-nowrap border-b-2 py-3 px-1 text-sm font-medium transition-colors " <>
                if @active_tab == "history",
                  do: "border-aurora_orange text-aurora_orange",
                  else: "border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700"}
            >
              <i class="fa-solid fa-list mr-2"></i>Movimientos
            </button>
          </nav>
        </div>

        <div class="mt-4">
          <%= case @active_tab do %>
            <% "general" -> %>
              <.ledger_general ledger={@ledger} balance={@balance} />
            <% "history" -> %>
              <.ledger_history entries={@entries} ledger={@ledger} />
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  defp ledger_general(assigns) do
    ~H"""
    <div class="space-y-6">
      <div class="grid grid-cols-2 gap-4 bg-gray-50 p-4 rounded-xl border border-gray-100">
        <div class="flex flex-col">
          <span class="text-xs text-gray-500 uppercase font-semibold">Saldo Actual</span>
          <span class={"text-2xl font-mono font-bold mt-1 " <> if(Decimal.compare(@balance, 0) == :lt, do: "text-red-600", else: "text-emerald-600")}>
            {AuroraGov.Web.CoreComponents.format_number(@balance)} {if Ecto.assoc_loaded?(@ledger.resource), do: @ledger.resource.unit_of_measure, else: ""}
          </span>
        </div>
        <div class="flex flex-col border-l border-gray-200 pl-4">
          <span class="text-xs text-gray-500 uppercase font-semibold">Naturaleza</span>
          <div class="mt-1">
            <%= case to_string(@ledger.ledger_type) do %>
              <% "asset" -> %><span class="px-2 py-1 rounded text-xs uppercase font-bold bg-green-50 text-green-700 border border-green-200">Activo (Asset)</span>
              <% "liability" -> %><span class="px-2 py-1 rounded text-xs uppercase font-bold bg-red-50 text-red-700 border border-red-200">Pasivo (Liability)</span>
              <% "equity" -> %><span class="px-2 py-1 rounded text-xs uppercase font-bold bg-purple-50 text-purple-700 border border-purple-200">Patrimonio (Equity)</span>
              <% "external" -> %><span class="px-2 py-1 rounded text-xs uppercase font-bold bg-blue-50 text-blue-700 border border-blue-200">Externa</span>
              <% _ -> %><span class="px-2 py-1 rounded text-xs uppercase font-bold bg-gray-50 text-gray-700 border border-gray-200">Desconocida</span>
            <% end %>
          </div>
        </div>
      </div>

      <div>
        <h4 class="text-xs text-gray-500 uppercase font-semibold mb-2">Descripción</h4>
        <p class="text-sm text-gray-700 bg-white border border-gray-100 p-4 rounded-lg leading-relaxed">
          {@ledger.description || "Esta cuenta no tiene una descripción configurada."}
        </p>
      </div>

      <div class="grid grid-cols-2 gap-4">
          <div>
            <h4 class="text-xs text-gray-500 uppercase font-semibold mb-1">Recurso Contabilizado</h4>
            <.resource_id_badge id={@ledger.resource_id} />
          </div>
        <div>
          <h4 class="text-xs text-gray-500 uppercase font-semibold mb-1">Propietario</h4>
          <p class="text-sm font-medium text-gray-800 wrap-break-word">{@ledger.owner_id}</p>
        </div>
      </div>
    </div>
    """
  end

  defp ledger_history(assigns) do
    ~H"""
    <div class="space-y-4">
      <%= if Enum.empty?(@entries) do %>
        <div class="flex flex-col items-center justify-center py-10 bg-gray-50 rounded-xl border border-gray-100">
          <i class="fa-solid fa-receipt text-3xl text-gray-300 mb-3"></i>
          <p class="text-gray-500 text-sm font-medium">Esta cuenta no tiene movimientos.</p>
        </div>
      <% else %>
        <div class="flow-root">
          <ul role="list" class="-mb-8">
            <%= for {entry, idx} <- Enum.with_index(@entries) do %>
              <li>
                <div class="relative pb-8">
                  <%= if idx != length(@entries) - 1 do %>
                    <span class="absolute left-5 top-5 -ml-px h-full w-0.5 bg-gray-200" aria-hidden="true"></span>
                  <% end %>
                  <div class="relative flex items-start space-x-3">
                    <div class="relative">
                      <span class={"h-10 w-10 rounded-full flex items-center justify-center ring-8 ring-white " <> if(Decimal.compare(entry.amount, 0) == :lt, do: "bg-red-50 text-red-500", else: "bg-emerald-50 text-emerald-500")}>
                        <i class={"fa-solid " <> if(Decimal.compare(entry.amount, 0) == :lt, do: "fa-arrow-right-from-bracket", else: "fa-arrow-right-to-bracket")}></i>
                      </span>
                    </div>
                    <div class="flex min-w-0 flex-1 justify-between space-x-4 pt-1.5">
                      <div>
                        <p class="text-sm text-gray-600 font-medium">
                          {entry.description || "Movimiento sin descripción"}
                        </p>
                        <%= if entry.reference_id do %>
                          <p class="text-xs text-gray-400 mt-1">
                            Ref: <span class="font-mono">{entry.reference_id}</span>
                          </p>
                        <% end %>
                      </div>
                      <div class="whitespace-nowrap text-right flex flex-col items-end">
                        <span class={"text-sm font-mono font-bold " <> if(Decimal.compare(entry.amount, 0) == :lt, do: "text-red-600", else: "text-emerald-600")}>
                          <%= if Decimal.compare(entry.amount, 0) == :gt, do: "+", else: "" %>{AuroraGov.Web.CoreComponents.format_number(entry.amount)} {if Ecto.assoc_loaded?(@ledger.resource), do: @ledger.resource.unit_of_measure, else: ""}
                        </span>
                        <time class="text-xs text-gray-400 mt-1">{Calendar.strftime(entry.timestamp, "%d/%m/%Y %H:%M")}</time>
                      </div>
                    </div>
                  </div>
                </div>
              </li>
            <% end %>
          </ul>
        </div>
      <% end %>
    </div>
    """
  end
end
