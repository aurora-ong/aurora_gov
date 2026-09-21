defmodule AuroraGov.Web.Live.Panel.Resources do
  require Logger
  use AuroraGov.Web, :live_component
  alias AuroraGov.Context.LedgerContext

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:resources, [])
      |> assign(:ledgers, [])
      |> assign(:loading, true)
      |> assign(:active_tab, "cuentas")

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_new(:active_ledger_filter, fn -> "all" end)
      |> load_data()

    {:ok, socket}
  end

  defp load_data(socket) do
    ou_id = socket.assigns.app_context.current_ou_id

    socket
    |> assign(:loading, true)
    |> start_async(:load_ledger_data, fn ->
      resources = LedgerContext.list_resources_by_ou(ou_id)
      ledgers = LedgerContext.list_ledgers_by_ou(ou_id)
      external_ledgers = LedgerContext.list_external_ledgers()

      ledgers_with_balance = Enum.map(ledgers ++ external_ledgers, fn acc ->
        %{ledger: acc, balance: LedgerContext.get_ledger_balance(acc.ledger_id)}
      end)

      {resources, ledgers_with_balance}
    end)
  end

  @impl true
  def handle_event("set_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, :active_tab, tab)}
  end

  @impl true
  def handle_event("set_filter", %{"filter" => filter}, socket) do
    {:noreply, assign(socket, :active_ledger_filter, filter)}
  end

  @impl true
  def handle_async(:load_ledger_data, {:ok, {resources, ledgers}}, socket) do
    socket =
      socket
      |> assign(:loading, false)
      |> assign(:resources, resources)
      |> assign(:ledgers, ledgers)

    {:noreply, socket}
  end

  def handle_async(:load_ledger_data, result, socket) do
    Logger.warning("Error loading ledger data: #{inspect(result)}")
    socket =
      socket
      |> assign(:loading, false)
      |> put_flash(:error, "No se pudieron cargar los datos del Ledger.")
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="w-full h-full">
      <div class="flex w-full h-12 flex-row justify-between mb-8 items-center border-b border-gray-100 pb-4">
        <div>
          <h2 class="text-2xl font-bold text-gray-800">Recursos y Cuentas</h2>
          <p class="text-sm text-gray-500">Gestión contable e inventario base de la unidad organizativa</p>
        </div>
        <div class="flex flex-row gap-3">
          <.app_button
            phx-click="open_proposal_create_modal"
            phx-value-proposal_ou_origin={@app_context.current_ou_id}
            phx-value-proposal_ou_end={@app_context.current_ou_id}
            phx-value-proposal_power_id="org.transaction.record"
            variant="outline"
            icon="fa-solid fa-money-bill-transfer"
          >
            Nueva Transacción
          </.app_button>

          <.app_button
            phx-click="open_proposal_create_modal"
            phx-value-proposal_ou_origin={@app_context.current_ou_id}
            phx-value-proposal_ou_end={@app_context.current_ou_id}
            phx-value-proposal_power_id="org.resource.create"
            variant="secondary"
            icon="fa-solid fa-plus"
          >
            Nuevo Recurso
          </.app_button>

          <.app_button
            phx-click="open_proposal_create_modal"
            phx-value-proposal_ou_origin={@app_context.current_ou_id}
            phx-value-proposal_ou_end={@app_context.current_ou_id}
            phx-value-proposal_power_id="org.ledger.create"
            variant="primary"
            icon="fa-solid fa-plus"
          >
            Nueva Cuenta
          </.app_button>
        </div>
      </div>

      <%= if @loading do %>
        <div class="flex items-center justify-center h-64">
          <.loading_spinner size="double_large" />
        </div>
      <% else %>
        <div class="flex flex-row gap-8 mb-6 border-b border-gray-200">
          <button phx-click="set_tab" phx-target={@myself} phx-value-tab="cuentas" class={"pb-2 text-sm font-bold border-b-2 transition-all duration-200 " <> if(@active_tab == "cuentas", do: "border-aurora_orange text-aurora_orange", else: "border-transparent text-gray-500 hover:text-gray-700")}>
            <i class="fa-solid fa-wallet mr-2"></i>Cuentas
          </button>
          <button phx-click="set_tab" phx-target={@myself} phx-value-tab="recursos" class={"pb-2 text-sm font-bold border-b-2 transition-all duration-200 " <> if(@active_tab == "recursos", do: "border-aurora_orange text-aurora_orange", else: "border-transparent text-gray-500 hover:text-gray-700")}>
            <i class="fa-solid fa-cube mr-2"></i>Recursos
          </button>
        </div>

        <div>
          <%= case @active_tab do %>
            <% "cuentas" -> %>
              <div class="mb-5 flex gap-2">
                <button phx-click="set_filter" phx-target={@myself} phx-value-filter="all" class={"px-3 py-1 rounded-full text-xs font-semibold " <> if(@active_ledger_filter == "all", do: "bg-gray-800 text-white", else: "bg-gray-100 text-gray-600 hover:bg-gray-200")}>Todas</button>
                <button phx-click="set_filter" phx-target={@myself} phx-value-filter="asset" class={"px-3 py-1 rounded-full text-xs font-semibold " <> if(@active_ledger_filter == "asset", do: "bg-green-100 text-green-800 border border-green-300", else: "bg-gray-50 text-gray-500 hover:bg-gray-100")}>Activos</button>
                <button phx-click="set_filter" phx-target={@myself} phx-value-filter="liability" class={"px-3 py-1 rounded-full text-xs font-semibold " <> if(@active_ledger_filter == "liability", do: "bg-red-100 text-red-800 border border-red-300", else: "bg-gray-50 text-gray-500 hover:bg-gray-100")}>Pasivos</button>
                <button phx-click="set_filter" phx-target={@myself} phx-value-filter="equity" class={"px-3 py-1 rounded-full text-xs font-semibold " <> if(@active_ledger_filter == "equity", do: "bg-purple-100 text-purple-800 border border-purple-300", else: "bg-gray-50 text-gray-500 hover:bg-gray-100")}>Patrimonio</button>
                <button phx-click="set_filter" phx-target={@myself} phx-value-filter="external" class={"px-3 py-1 rounded-full text-xs font-semibold " <> if(@active_ledger_filter == "external", do: "bg-blue-100 text-blue-800 border border-blue-300", else: "bg-gray-50 text-gray-500 hover:bg-gray-100")}>Externas</button>
              </div>
              <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                <%= for item <- Enum.filter(@ledgers, fn a -> @active_ledger_filter == "all" || to_string(a.ledger.ledger_type) == @active_ledger_filter end) do %>
                  <% is_selected = assigns[:app_side_panel] && assigns[:app_side_panel].view_id == "panel-ledger-#{item.ledger.ledger_id}" %>
                  <div class={"p-5 border rounded-xl bg-white transition-shadow cursor-pointer " <>
                     (if is_selected, do: "shadow-md ring-2 ring-aurora_orange ", else: "shadow-sm hover:shadow-md ") <>
                     (case item.ledger.ledger_type do
                        :asset -> "border-green-200 border-t-4 border-t-green-500"
                        :liability -> "border-red-200 border-t-4 border-t-red-500"
                        :equity -> "border-purple-200 border-t-4 border-t-purple-500"
                        :external -> "border-blue-200 border-t-4 border-t-blue-500"
                        _ -> "border-gray-200"
                      end)} phx-click="push_patch" phx-value-url={"/app/ledger/#{item.ledger.ledger_id}?context=#{@app_context.current_ou_id}"}>
                    <div class="flex justify-between items-start mb-3">
                      <div>
                        <div class="font-bold text-gray-900 text-lg">{item.ledger.name || "Cuenta sin nombre"}</div>
                        <div class="flex items-center gap-2 mt-2 flex-wrap">
                          <.ledger_id_badge id={item.ledger.ledger_id} />
                          <%= case to_string(item.ledger.ledger_type) do %>
                            <% "asset" -> %><span class="px-1.5 py-0.5 rounded text-[10px] uppercase font-bold bg-green-50 text-green-700 border border-green-200">Activo</span>
                            <% "liability" -> %><span class="px-1.5 py-0.5 rounded text-[10px] uppercase font-bold bg-red-50 text-red-700 border border-red-200">Pasivo</span>
                            <% "equity" -> %><span class="px-1.5 py-0.5 rounded text-[10px] uppercase font-bold bg-purple-50 text-purple-700 border border-purple-200">Patrimonio</span>
                            <% "external" -> %><span class="px-1.5 py-0.5 rounded text-[10px] uppercase font-bold bg-blue-50 text-blue-700 border border-blue-200">Externa</span>
                            <% _ -> %><span class="px-1.5 py-0.5 rounded text-[10px] uppercase font-bold bg-gray-50 text-gray-700 border border-gray-200">Desconocido</span>
                          <% end %>
                        </div>
                      </div>
                    </div>
                    <%= if item.ledger.description do %>
                      <p class="text-sm text-gray-600 mb-4 h-10 overflow-hidden text-ellipsis line-clamp-2">
                        {item.ledger.description}
                      </p>
                    <% else %>
                      <div class="mb-4 h-10"></div>
                    <% end %>
                    <div class="pt-3 border-t border-gray-100 flex justify-between items-end">
                      <.resource_id_badge id={item.ledger.resource_id} />
                      <div class="text-right">
                        <div class="text-[10px] text-gray-400 uppercase tracking-widest mb-1">Saldo Actual</div>
                        <div class={"font-mono text-xl font-bold " <> if(Decimal.compare(item.balance, 0) == :lt, do: "text-red-600", else: "text-emerald-600")}>
                          {AuroraGov.Web.CoreComponents.format_number(item.balance)} {if Ecto.assoc_loaded?(item.ledger.resource), do: item.ledger.resource.unit_of_measure, else: ""}
                        </div>
                      </div>
                    </div>
                  </div>
                <% end %>
                <%= if Enum.empty?(@ledgers) do %>
                  <div class="col-span-full flex flex-col items-center justify-center p-12 bg-gray-50 rounded-xl border-2 border-dashed border-gray-200">
                     <i class="fa-solid fa-wallet text-3xl text-gray-300 mb-3"></i>
                     <p class="text-gray-500 text-sm font-medium">Esta unidad aún no tiene cuentas</p>
                  </div>
                <% end %>
              </div>

            <% "recursos" -> %>
              <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                <%= for resource <- @resources do %>
                  <div class="p-5 border border-gray-200 rounded-xl bg-gray-50 hover:shadow-sm transition-shadow">
                    <div class="flex justify-between items-start mb-3">
                      <div class="font-bold text-gray-800 text-lg">{resource.name}</div>
                      <span class={"text-[10px] uppercase tracking-wider font-semibold px-2.5 py-1 rounded-full " <> if(resource.is_fungible, do: "bg-blue-100 text-blue-800", else: "bg-purple-100 text-purple-800")}>
                        {if resource.is_fungible, do: "Fungible", else: "Único"}
                      </span>
                    </div>
                    <div class="flex flex-col gap-2 mt-4">
                      <div class="text-sm text-gray-600 flex justify-between">
                        <span class="text-gray-400">Unidad de medida:</span>
                        <span class="font-bold">{resource.unit_of_measure}</span>
                      </div>
                      <%= if resource.description do %>
                        <div class="mt-3 text-sm text-gray-500 italic line-clamp-2">
                          {resource.description}
                        </div>
                      <% end %>
                      <div class="mt-2 pt-2 border-t border-gray-200">
                        <.resource_id_badge id={resource.id} />
                      </div>
                    </div>
                  </div>
                <% end %>
                <%= if Enum.empty?(@resources) do %>
                  <div class="col-span-full flex flex-col items-center justify-center p-12 bg-gray-50 rounded-xl border-2 border-dashed border-gray-200">
                     <i class="fa-solid fa-cube text-3xl text-gray-300 mb-3"></i>
                     <p class="text-gray-500 text-sm font-medium">No hay recursos definidos</p>
                  </div>
                <% end %>
              </div>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end
end
