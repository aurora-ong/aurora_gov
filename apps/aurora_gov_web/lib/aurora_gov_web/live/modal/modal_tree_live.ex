defmodule TreePanelComponent do
  alias Phoenix.LiveView.AsyncResult
  use AuroraGovWeb, :live_component
  import AuroraGovWeb.OUVisualTreeComponent

  @impl true
  def mount(socket) do
    IO.inspect(socket.assigns)

    socket =
      socket
      |> assign(:ou_tree, AsyncResult.loading())

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(:context, assigns.context)
      |> assign(:module, assigns.app_module)
      |> start_async(:load_data, fn ->
        if assigns[:current_person] != nil do
          AuroraGov.Context.OUContext.get_ou_tree_with_membership(
            assigns[:current_person].person_id
          )
        else
          AuroraGov.Context.OUContext.get_ou_tree() |> Enum.map(&Map.from_struct/1)
        end
      end)

    {:ok, socket}
  end

  @impl true
  def handle_async(:load_data, {:ok, ou_tree}, socket) do
    %{ou_tree: ou_tree_async} = socket.assigns
    {:noreply, assign(socket, :ou_tree, AsyncResult.ok(ou_tree_async, ou_tree))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <section class="flex flex-col h-fit">
      <h2 class="text-3xl font-semibold mb-5 flex flex-row items-center justify-center">
        <i class="fa-solid fa-sitemap mr-3 text-3xl rotate-180"></i>Estructura organizativa
      </h2>

      <.async_result :let={ou_tree} assign={@ou_tree}>
        <:loading>
          <.loading_spinner></.loading_spinner>
        </:loading>

        <:failed :let={_failure}>there was an error loading the organization</:failed>

        <.ou_visual_tree ou_tree={ou_tree}>
          <:ou_item :let={ou}>
            <.link patch={~p"/app/#{@module}?context=#{ou.ou_id}"} replace>
              <div class={"cursor-pointer hover:bg-gray-100 px-5 py-3 rounded-lg my-1 flex flex-row items-center #{if @context == ou.ou_id, do: "border-2 border-aurora_orange", else: "border"}" }>
                <div class="flex flex-col flex-grow">
                  <span class="text-white w-fit bg-black px-2 py-0.5 font-semibold text-sm rounded">
                    {ou.ou_id}
                  </span>

                  <div class="text-aurora_orange font-bold text-lg">{ou.ou_name}</div>

                  <div class="text-xs">{ou.ou_goal}</div>
                </div>

                <div class="px-5 flex flex-row gap-3">
                  <%= if ou[:membership_status] != nil do %>
                    <i class="fa-solid fa-person-circle-check text-4xl"></i>
                  <% end %>

                  <%= if @context == ou.ou_id do %>
                    <i class="fa-solid fa-location-pin text-4xl text-aurora_orange"></i>
                  <% end %>
                </div>
              </div>
            </.link>
          </:ou_item>
        </.ou_visual_tree>
      </.async_result>
    </section>
    """
  end
end
