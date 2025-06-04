defmodule PanelHeaderComponent do
  use AuroraGovWeb, :live_component
  alias Phoenix.LiveView.JS

  def update(assigns, socket) do
    socket =
      socket
      |> assign(:context, assigns.context)
      |> assign(:module, assigns.app_module)
      |> assign(:uri, assigns.uri)
      |> assign(:ou, AuroraGov.Projector.OU.get_ou_by_id(assigns.context))

    # |> assign(:ou_list, assigns.ou_tree)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <section class="card w-full flex flex-row h-fit justify-center items-center">
      <div class="flex flex-col flex-grow">
        <h2 class="text-white w-fit bg-black px-2 py-0.5 font-bold rounded">{@ou.ou_id}</h2>

        <h1 class="text-4xl">{@ou.ou_name}</h1>

        <h2>{@ou.ou_goal}</h2>
      </div>

      <div class="flex flex-row gap-3 items-center justify-center h-full">
        <.link patch={~p"/app/#{@module}?context=#{@context}&gov-modal=true"}>
          <button class="justify-center items-center text-lg primary">
            <i class="fa-solid fa-hand text-xl"></i> Gobernar
          </button>
        </.link>

        <.link patch={~p"/app/#{@module}?context=#{@context}&tree-modal=true"}>
          <button class="justify-center items-center text-lg primary">
            <i class="fa-solid fa-sitemap text-xl"></i> Navegar
          </button>
        </.link>

        <%!-- <button class="justify-center items-center text-lg primary h-full">
          <i class="fa-solid fa-arrow-up text-xl"></i>
        </button>

        <button class="justify-center items-center text-lg primary">
          <i class="fa-solid fa-arrow-down text-xl"></i>
        </button> --%>
      </div>
    </section>
    """
  end

  def show_navigate(js \\ %JS{}) do
    js
    |> JS.toggle_class("hidden", to: "#dropdown")
  end
end
