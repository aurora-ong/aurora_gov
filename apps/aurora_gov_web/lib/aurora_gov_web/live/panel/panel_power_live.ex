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
      <.async_result :let={ou_power_list} assign={@ou_power_list}>
        <:loading>
          <.loading_spinner></.loading_spinner>
        </:loading>

        <:failed :let={_failure}>error loading</:failed>

        <div class="grid grid-cols-2 gap-4">
          <%= for power <- ou_power_list do %>
            <.live_component
              module={AuroraGovWeb.Components.Power.PowerCardComponent}
              id={"power-card-#{power.id}"}
              power_id={power.id}
              show_actions={true}
              power_info={power.power_info}
              ou_power={power.ou_power}
              parent_target={@myself}
            />
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
