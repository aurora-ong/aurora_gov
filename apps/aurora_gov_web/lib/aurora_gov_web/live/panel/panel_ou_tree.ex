defmodule AuroraGovWeb.PanelOUTreeComponent do
  use AuroraGovWeb, :live_component

  alias Phoenix.LiveView.JS

  def update(assigns, socket) do
    socket =
      socket
      |> assign(:context, assigns.context)
      |> assign(:module, assigns.app_module)
      |> assign(:ou_tree, assigns.ou_tree)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <section class="w-full flex flex-col h-fit">
      <h1 class="text-4xl text-black mb-10">Navegar estructura</h1>

      <div class="flex flex-col grow gap-1.5">
        <%= for ou <- @ou_tree do %>
          <.link
            patch={~p"/app/#{@module}?context=#{ou.ou_id}"}
            replace
            class={
              if @context == ou.ou_id,
                do: "flex flex-col grow bg-aurora_orange rounded-lg px-5 py-4 text-white",
                else:
                  "flex flex-col grow border border-black hover:bg-gray-200/75 rounded-lg px-5 py-4"
            }
          >
            <div class="flex flex-row items-center gap-3">
              <%!-- <i class="fa-solid fa-people-roof text-2xl"></i> --%>
              <div class="flex flex-col flex-grow">
                <h2 class={
                  if @context == ou.ou_id,
                    do: "w-fit text-white bg-black font-bold rounded px-2 py-0.5",
                    else: "w-fit border text-black font-bold rounded px-2 py-0.5"
                }>
                  {ou.ou_id}
                </h2>

                <h1 class="text-lg">{ou.ou_name}</h1>
              </div>

              <div>
                <%= if ou.membership_status != nil do %>
                  <i class="fa-solid fa-person-circle-check text-2xl"></i>
                <% end %>
              </div>
            </div>
          </.link>
        <% end %>
      </div>
    </section>
    """
  end

  def show_navigate(js \\ %JS{}) do
    js
    |> JS.toggle_class("hidden", to: "#dropdown")
  end
end
