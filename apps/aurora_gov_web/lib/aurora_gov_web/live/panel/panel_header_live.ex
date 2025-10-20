defmodule AuroraGovWeb.Live.Panel.Header do
  use AuroraGovWeb, :live_component
  alias Phoenix.LiveView.JS

  def update(assigns, socket) do
    IO.inspect(assigns, label: "PanelHeaderComponent Update")

    socket =
      socket
      |> assign(:context, assigns.context)
      # |> assign(:module, assigns.app_module)
      # |> assign(:uri, assigns.uri)
      |> assign(:ou, AuroraGov.Context.OUContext.get_ou_by_id(assigns.context))

    # |> assign(:ou_list, assigns.ou_tree)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <section class="card w-full flex flex-row h-fit justify-center items-center gap-5 px-10 py-6">
      <div class="flex flex-col flex-grow">
        <.ou_id_badge size="lg" ou_id={@ou.ou_id} />
        <h1 class="text-4xl">{@ou.ou_name}</h1>
      </div>

      <div class="flex flex-row gap-3 items-center justify-center h-full">
        <button
          phx-click="open_gov_modal"
          phx-value-proposal_ou_origin={@ou.ou_id}
          class="text-lg primary outlined"
        >
          <i class="fa-solid fa-hand text-xl"></i> Gobernar
        </button>

        <button phx-click="open_tree_modal" class="text-lg primary outlined">
          <i class="fa-solid fa-sitemap text-xl rotate-180"></i> Navegar
        </button>

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
