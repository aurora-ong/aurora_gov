defmodule TreePanelComponent do
  use AuroraGovWeb, :live_component
  import AuroraGovWeb.OUVisualTreeComponent

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(:context, assigns.context)
      |> assign(:module, assigns.app_module)
      |> assign(:ou_tree, assigns.ou_tree)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <section class="flex flex-col h-fit">
      <h2 class="text-3xl font-semibold mb-5 flex flex-row items-center justify-center"><i class="fa-solid fa-sitemap mr-3 text-3xl"></i>Estructura organizativa</h2>

      <.ou_visual_tree ou_tree={@ou_tree}>
        <:ou_item :let={ou}>
          <.link patch={~p"/app/#{@module}?context=#{ou.ou_id}"} replace>
            <div class={"cursor-pointer hover:bg-gray-100 rounded px-5 py-3 rounded-lg my-1 flex flex-row items-center #{if @context == ou.ou_id, do: "border-2 border-aurora_orange", else: "border"}" }>
              <div class="flex flex-col flex-grow">
                <span class="text-white w-fit bg-black px-2 py-0.5 font-semibold text-sm rounded">
                  {ou.ou_id}
                </span>

                <div class="text-aurora_orange font-bold text-lg">{ou.ou_name}</div>

                <div class="text-xs">{ou.ou_goal}</div>
              </div>

              <div class="px-5">
                <%= if @context == ou.ou_id do %>
                  <i class="fa-solid fa-location-pin text-4xl text-aurora_orange"></i>
                <% end %>

                <%= if ou.membership_status != nil do %>
                  <i class="fa-solid fa-person-circle-check text-4xl"></i>
                <% end %>
              </div>
            </div>
          </.link>
        </:ou_item>
      </.ou_visual_tree>
    </section>
    """
  end
end
