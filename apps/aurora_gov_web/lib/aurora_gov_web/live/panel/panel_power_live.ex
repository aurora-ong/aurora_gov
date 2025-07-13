defmodule PowerPanelComponent do
  alias Phoenix.LiveView.AsyncResult
  use AuroraGovWeb, :live_component

  @impl true
  def update(%{update: {:power_updated, %{ou_id: ou_id}}}, socket) do
    socket =
      if ou_id == socket.assigns.context do
        socket
        |> assign(:ou_power_list, AsyncResult.loading())
        |> start_async(:load_data, fn ->
          AuroraGov.Context.PowerContext.get_ou_power_list(ou_id)
        end)
      else
        socket
      end

    {:ok, socket}
  end

  @impl true
  def update(%{close_modal: modal}, socket) do
    IO.inspect("CLose modal #{modal}")

    {:ok, assign(socket, power_modal: false)}
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(:context, assigns.context)
      |> assign(:ou_power_list, AsyncResult.loading())
      |> assign(power_modal: false)
      |> assign(power_modal_power_id: nil)
      |> start_async(:load_data, fn ->
        :timer.sleep(1000)
        AuroraGov.Context.PowerContext.get_ou_power_list(assigns.context)
      end)

    {:ok, socket}
  end

  @impl true
  def handle_async(:load_data, {:ok, ou_powers}, socket) do
    power_info =
      AuroraGov.CommandUtils.all_proposable_modules()
      |> Enum.map(fn module ->
        Map.merge(module.gov_power(), %{})
      end)

    power_ids =
      (Enum.map(power_info, & &1.id) ++ Enum.map(ou_powers, & &1.power_id))
      |> Enum.uniq()

    combined =
      Enum.map(power_ids, fn id ->
        %{
          id: id,
          power_info: Enum.find(power_info, &(&1.id == id)),
          ou_power: Enum.find(ou_powers, &(&1.power_id == id))
        }
      end)

    %{ou_power_list: ou_power_list} = socket.assigns
    {:noreply, assign(socket, :ou_power_list, AsyncResult.ok(ou_power_list, combined))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <section class="card w-4/6 flex flex-col h-fit">
      <h2 class="text-2xl font-bold mb-6">Tabla de consensos</h2>

      <.async_result :let={ou_power_list} assign={@ou_power_list}>
        <:loading>
          <.loading_spinner></.loading_spinner>
        </:loading>

        <:failed :let={_failure}>error loading</:failed>

        <div class="grid grid-cols-2 gap-4">
          <%= for power <- ou_power_list do %>
            <div class="border px-5 py-5 rounded-lg flex flex-col justify-between">
              <div class="flex justify-between items-start">
                <div>
                  <h3 class="text-lg font-semibold">
                    {get_in(power, [:power_info, :name]) || power.id}
                  </h3>

                  <p class="text-sm text-gray-600">
                    {get_in(power, [:power_info, :description]) || ""}
                  </p>
                </div>

                <div class="flex flex-row gap-1">
                  <button
                    phx-click="update_power"
                    phx-value-power_id={power.id}
                    phx-target={@myself}
                    class="justify-center items-center text-lg primary !px-3"
                  >
                    <i class="fa-solid fa-hand-point-up text-sm"></i>
                  </button>

                  <button
                    phx-click="update_power"
                    phx-value-power_id={power.id}
                    phx-target={@myself}
                    class="justify-center items-center text-lg primary !px-3"
                  >
                    <i class="fa-solid fa-eye text-sm"></i>
                  </button>
                </div>
              </div>

              <div :if={power.ou_power != nil} class="mt-3">
                <div class="flex flex-row">
                  <label class="text-sm text-gray-500 flex-grow">
                    Requiere <strong>{power.ou_power.power_average}%</strong> de aprobación colectiva
                  </label>

                  <span class="text-sm flex flex-row items-center gap-1">
                    <%!-- {power.ou_poder}/{power.power_person_total} --%>
                    10/10
                    <i class="fa-solid fa-user-group text-sm"></i>
                  </span>
                </div>

                <div class="w-full bg-gray-200 rounded-full h-2 mt-1">
                  <div
                    class={"#{get_progress_bar_color(Decimal.to_float(power.ou_power.power_average))} h-2 rounded-full"}
                    style={"width: #{power.ou_power.power_average}%;"}
                  >
                  </div>
                </div>

                <p class="text-xs text-gray-500 mt-2 flex flex-row items-center">
                  <%!-- <i class="fa-solid fa-hand mr-2" />Usado {power.power_use_7_days} veces en los últimos 7 días --%>
                </p>
              </div>
                        <div :if={power.ou_power == nil} class="mt-3">
                <div class="flex flex-row">
                  <label class="text-sm text-gray-500 flex-grow">
                    Sin postura
                  </label>

                  <span class="text-sm flex flex-row items-center gap-1">
                    0/12
                    <i class="fa-solid fa-user-group text-sm"></i>
                  </span>
                </div>

                <div class="w-full bg-gray-200 rounded-full h-2 mt-1">
                  <div
                    class="bg-gray-600 h-2 rounded-full"
                    style={"width: 50%;"}
                  >
                  </div>
                </div>

                <p class="text-xs text-gray-500 mt-2 flex flex-row items-center">
                  <%!-- <i class="fa-solid fa-hand mr-2" />Usado {power.power_use_7_days} veces en los últimos 7 días --%>
                </p>
              </div>
            </div>
          <% end %>
        </div>
      </.async_result>

      <.modal
        :if={@power_modal}
        id="power-modal"
        show
        max_width="max-w-3xl"
        on_cancel={JS.push("modal_closed", target: @myself, value: %{modal: "power_update_modal"})}
      >
        <.live_component
          module={AuroraGovWeb.App.Power.PowerSensibilityModalLive}
          id={"power-modal-#{@power_modal_power_id}"}
          context={@context}
          power_id={@power_modal_power_id}
        />
      </.modal>
    </section>
    """
  end

  defp get_progress_bar_color(power_consensus) do
    cond do
      power_consensus <= 33 ->
        "bg-blue-600"

      power_consensus >= 66 ->
        "bg-red-600"

      true ->
        "bg-aurora_orange"
    end
  end

  @impl true
  def handle_event("update_power", %{"power_id" => power_id}, socket) do
    IO.inspect(power_id, label: "update_power")

    socket =
      socket
      |> assign(power_modal_power_id: power_id)
      |> assign(power_modal: true)

    {:noreply, socket}
  end

  @impl true
  def handle_event("modal_closed", %{"modal" => "power_update_modal"}, socket) do
    IO.inspect("Cerrando modal power_update_modal")
    {:noreply, assign(socket, power_modal: false)}
  end
end
