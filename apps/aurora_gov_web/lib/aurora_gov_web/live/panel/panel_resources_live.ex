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

      ledgers_with_balance =
        Enum.map(ledgers ++ external_ledgers, fn acc ->
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
    filtered_ledgers =
      Enum.filter(assigns.ledgers, fn a ->
        assigns.active_ledger_filter == "all" ||
          to_string(a.ledger.ledger_type) == assigns.active_ledger_filter
      end)

    assigns = assign(assigns, :filtered_ledgers, filtered_ledgers)

    ~H"""
    <div class="w-full h-full">
      <div class="flex w-full min-h-12 flex-row justify-between items-center gap-3 mb-5">
        <div class="flex flex-row gap-6 border-b border-gray-200">
          <button
            type="button"
            phx-click="set_tab"
            phx-target={@myself}
            phx-value-tab="cuentas"
            class={
              "pb-2.5 text-sm font-bold border-b-2 transition-all duration-200 cursor-pointer " <>
                if(@active_tab == "cuentas",
                  do: "border-aurora_orange text-aurora_orange",
                  else: "border-transparent text-gray-500 hover:text-gray-700"
                )
            }
          >
            <i class="fa-solid fa-wallet mr-2"></i>Cuentas
          </button>
          <button
            type="button"
            phx-click="set_tab"
            phx-target={@myself}
            phx-value-tab="recursos"
            class={
              "pb-2.5 text-sm font-bold border-b-2 transition-all duration-200 cursor-pointer " <>
                if(@active_tab == "recursos",
                  do: "border-aurora_orange text-aurora_orange",
                  else: "border-transparent text-gray-500 hover:text-gray-700"
                )
            }
          >
            <i class="fa-solid fa-cube mr-2"></i>Recursos
          </button>
        </div>

        <div class="flex flex-row items-center gap-2 sm:gap-3 shrink-0">
          <.action_dropdown id="resources-actions">
            <:item
              icon="fa-solid fa-money-bill-transfer"
              label="Nueva Transacción"
              proposal_ou_origin={@app_context.current_ou_id}
              proposal_ou_end={@app_context.current_ou_id}
              proposal_power_id="org.transaction.record"
            />
            <:item
              icon="fa-solid fa-cube"
              label="Nuevo Recurso"
              proposal_ou_origin={@app_context.current_ou_id}
              proposal_ou_end={@app_context.current_ou_id}
              proposal_power_id="org.resource.create"
            />
            <:item
              icon="fa-solid fa-wallet"
              label="Nueva Cuenta"
              proposal_ou_origin={@app_context.current_ou_id}
              proposal_ou_end={@app_context.current_ou_id}
              proposal_power_id="org.ledger.create"
            />
          </.action_dropdown>
        </div>
      </div>

      <%= if @loading do %>
        <div class="flex items-center justify-center h-64">
          <.loading_spinner size="double_large" />
        </div>
      <% else %>
        <div>
          <%= case @active_tab do %>
            <% "cuentas" -> %>
              <div class="mb-5">
                <.filter_button_group
                  options={[
                    %{label: "Todas", value: "all"},
                    %{label: "Activos", value: "asset"},
                    %{label: "Pasivos", value: "liability"},
                    %{label: "Patrimonio", value: "equity"},
                    %{label: "Externas", value: "external"}
                  ]}
                  selected={@active_ledger_filter}
                  on_select="set_filter"
                  phx_target={@myself}
                />
              </div>

              <%= if Enum.empty?(@filtered_ledgers) do %>
                <div class="flex flex-col items-center justify-center py-20 px-4 text-center bg-gray-50 rounded-2xl border-2 border-dashed border-gray-200">
                  <i class="fa-solid fa-wallet text-5xl text-gray-300 mb-4"></i>
                  <h3 class="text-lg font-semibold text-gray-700">No se encontraron cuentas</h3>
                  <p class="text-sm text-gray-400 mt-1">
                    <%= if @active_ledger_filter == "all" do %>
                      Esta unidad aún no tiene cuentas registradas. Crea una propuesta para abrir una nueva cuenta.
                    <% else %>
                      No hay cuentas registradas bajo la categoría seleccionada.
                    <% end %>
                  </p>
                </div>
              <% else %>
                <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                  <%= for item <- @filtered_ledgers do %>
                    <% is_selected =
                      assigns[:app_side_panel] &&
                        assigns[:app_side_panel].view_id == "panel-ledger-#{item.ledger.ledger_id}" %>
                    <div
                      class={
                        "p-5 border rounded-xl bg-white transition-shadow cursor-pointer " <>
                          if(is_selected,
                            do: "shadow-md ring-2 ring-aurora_orange ",
                            else: "shadow-sm hover:shadow-md "
                          ) <>
                          case item.ledger.ledger_type do
                            :asset -> "border-green-200 border-t-4 border-t-green-500"
                            :liability -> "border-red-200 border-t-4 border-t-red-500"
                            :equity -> "border-purple-200 border-t-4 border-t-purple-500"
                            :external -> "border-blue-200 border-t-4 border-t-blue-500"
                            _ -> "border-gray-200"
                          end
                      }
                      phx-click="push_patch"
                      phx-value-url={"/app/ledger/#{item.ledger.ledger_id}?context=#{@app_context.current_ou_id}"}
                    >
                      <div class="flex justify-between items-start mb-3">
                        <div>
                          <div class="font-bold text-gray-900 text-lg">
                            {item.ledger.name || "Cuenta sin nombre"}
                          </div>
                          <div class="flex items-center gap-2 mt-2 flex-wrap">
                            <.ledger_id_badge id={item.ledger.ledger_id} />
                            <%= case to_string(item.ledger.ledger_type) do %>
                              <% "asset" -> %>
                                <span class="px-1.5 py-0.5 rounded text-[10px] uppercase font-bold bg-green-50 text-green-700 border border-green-200">
                                  Activo
                                </span>
                              <% "liability" -> %>
                                <span class="px-1.5 py-0.5 rounded text-[10px] uppercase font-bold bg-red-50 text-red-700 border border-red-200">
                                  Pasivo
                                </span>
                              <% "equity" -> %>
                                <span class="px-1.5 py-0.5 rounded text-[10px] uppercase font-bold bg-purple-50 text-purple-700 border border-purple-200">
                                  Patrimonio
                                </span>
                              <% "external" -> %>
                                <span class="px-1.5 py-0.5 rounded text-[10px] uppercase font-bold bg-blue-50 text-blue-700 border border-blue-200">
                                  Externa
                                </span>
                              <% _ -> %>
                                <span class="px-1.5 py-0.5 rounded text-[10px] uppercase font-bold bg-gray-50 text-gray-700 border border-gray-200">
                                  Desconocido
                                </span>
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
                          <div class="text-[10px] text-gray-400 uppercase tracking-widest mb-1">
                            Saldo Actual
                          </div>
                          <div class={
                            "font-mono text-xl font-bold " <>
                              if(Decimal.compare(item.balance, 0) == :lt,
                                do: "text-red-600",
                                else: "text-emerald-600"
                              )
                          }>
                            {AuroraGov.Web.CoreComponents.format_number(item.balance)} {if Ecto.assoc_loaded?(
                                                                                             item.ledger.resource
                                                                                           ),
                                                                                           do:
                                                                                             item.ledger.resource.unit_of_measure,
                                                                                           else: ""}
                          </div>
                        </div>
                      </div>
                    </div>
                  <% end %>
                </div>
              <% end %>
            <% "recursos" -> %>
              <%= if Enum.empty?(@resources) do %>
                <div class="flex flex-col items-center justify-center py-20 px-4 text-center bg-gray-50 rounded-2xl border-2 border-dashed border-gray-200">
                  <i class="fa-solid fa-cube text-5xl text-gray-300 mb-4"></i>
                  <h3 class="text-lg font-semibold text-gray-700">No hay recursos definidos</h3>
                  <p class="text-sm text-gray-400 mt-1">
                    Crea una propuesta de gobernanza para registrar un nuevo recurso en el inventario.
                  </p>
                </div>
              <% else %>
                <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                  <%= for resource <- @resources do %>
                    <div class="p-5 border border-gray-200 rounded-xl bg-gray-50 hover:shadow-sm transition-shadow">
                      <div class="flex justify-between items-start mb-3">
                        <div class="font-bold text-gray-800 text-lg">{resource.name}</div>
                        <span class={
                          "text-[10px] uppercase tracking-wider font-semibold px-2.5 py-1 rounded-full " <>
                            if(resource.is_fungible,
                              do: "bg-blue-100 text-blue-800",
                              else: "bg-purple-100 text-purple-800"
                            )
                        }>
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
                </div>
              <% end %>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end
end
