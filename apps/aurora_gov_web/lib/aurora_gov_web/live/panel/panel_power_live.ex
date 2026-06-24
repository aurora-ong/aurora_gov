defmodule AuroraGov.Web.Live.Panel.Power do
  alias Phoenix.LiveView.AsyncResult
  use AuroraGov.Web, :live_component

  defp load_data(ou_id) do
    ou_power_list =
      AuroraGov.Context.OuPowerContext.list_ou_power(ou_id)

    ou_vote_membership_count =
      AuroraGov.Context.MembershipContext.count_active_memberships_by_ou(
        ou_id,
        [:regular, :senior]
      )

    {ou_power_list, ou_vote_membership_count}
  end

  @impl true
  def mount(socket) do
    {:ok, assign(socket, :filter, "all")}
  end

  @impl true
  def update(%{update: {:power_updated, %{ou_id: ou_id}}}, socket) do
    socket =
      if ou_id == socket.assigns.app_context.current_ou_id do
        socket
        |> assign(:ou_power_list, AsyncResult.loading())
        |> start_async(:load_data, fn -> load_data(ou_id) end)
      else
        socket
      end

    {:ok, socket}
  end

  @impl true
  def update(%{close_modal: modal}, socket) do
    IO.inspect("Close modal #{modal}")

    {:ok, assign(socket, power_modal: false)}
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(:app_context, assigns.app_context)
      |> assign(:ou_power_list, AsyncResult.loading())
      |> assign(power_modal: false)
      |> assign(power_modal_power_id: nil)
      |> assign(ou_vote_membership_count: nil)
      |> start_async(:load_data, fn -> load_data(assigns.app_context.current_ou_id) end)

    {:ok, socket}
  end

  @impl true
  def handle_async(:load_data, {:ok, {ou_powers, ou_vote_membership_count}}, socket) do
    power_info =
      AuroraGov.Context.GovPowerContext.list_gov_power()

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

    socket =
      socket
      |> assign(:ou_power_list, AsyncResult.ok(ou_power_list, combined))
      |> assign(:ou_vote_membership_count, ou_vote_membership_count)

    {:noreply, socket}
  end

  @impl true
  def handle_event("update_filter", %{"filter" => filter}, socket) do
    {:noreply, assign(socket, :filter, filter)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="h-full w-full p-6">
      <div class="flex w-full h-12 flex-row justify-between mb-5 items-center">
        <.filter_button_group
          options={[
            %{label: "Todos", value: "all"},
            %{label: "Unidad", value: "ou"},
            %{label: "Membresía", value: "membership"},
            %{label: "Roles", value: "role"}
          ]}
          selected={@filter}
          on_select="update_filter"
          phx_target={@myself}
        />
      </div>

      <.async_result :let={ou_power_list} assign={@ou_power_list}>
        <:loading><.loading_spinner size="double_large" /></:loading>

        <:failed :let={_failure}>error loading</:failed>

        <div class="grid grid-cols-3 gap-4">
          <%= for power <- filter_powers(ou_power_list, @filter) do %>
            <.live_component
              module={AuroraGov.Web.Components.Power.PowerCardComponent}
              id={"power-card-#{power.id}"}
              power_id={power.id}
              show_actions={true}
              power_info={power.power_info}
              app_context={@app_context}
              ou_power={power.ou_power}
              ou_vote_membership_count={@ou_vote_membership_count}
              parent_target={@myself}
            />
          <% end %>
        </div>
      </.async_result>
    </div>
    """
  end

  defp filter_powers(ou_power_list, "all"), do: ou_power_list
  defp filter_powers(ou_power_list, category) do
    Enum.filter(ou_power_list, fn power ->
      power.power_info && to_string(power.power_info.category) == to_string(category)
    end)
  end
end
