defmodule AuroraGov.Web.Live.Panel.Header do
  alias AuroraGov.Web.Live.Panel.AppView
  use AuroraGov.Web, :live_component
  alias Phoenix.LiveView.JS

  @impl true
  def update(assigns, socket) do
    IO.inspect(assigns, label: "PanelHeaderComponent Update")

    socket =
      socket
      |> assign(:app_context, assigns.app_context)
      |> assign(:ou, AuroraGov.Context.OUContext.get_ou(assigns.app_context.current_ou_id))

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="w-full bg-white rounded-xl h-fit shadow-sm border border-gray-200 relative group transition px-5 py-4">
      <div class="absolute top-0 left-0 w-full h-2 rounded-xl rounded-b-none transition bg-aurora_blue_light ">
      </div>

      <div class="flex flex-col md:flex-row justify-between items-start md:items-center gap-4 mt-2">
        <div class="flex items-start gap-3">
          <div class="w-16 h-16 rounded-lg bg-blue-50 flex items-center justify-center text-aurora_orange shadow-sm border border-blue-100 shrink-0">
            <i class="fa-solid fa-sitemap text-2xl"></i>
          </div>
          <div class="flex flex-col">
            <h1 class="text-2xl font-bold text-gray-900">{@ou.ou_name}</h1>
            <div class="flex items-center gap-3 mt-2">
              <.ou_id_badge id={@ou.ou_id} patch={~p"/app/home?context=#{@ou.ou_id}"} />
              <span class="text-gray-400 text-sm border-l border-gray-300 pl-3">
                Fundada el {@ou.created_at |> Calendar.strftime("%d/%m/%Y")}
              </span>
            </div>
          </div>
        </div>

        <div class="flex flex-row gap-3 items-center justify-center h-full">
          <.app_button
            phx-click="open_proposal_create_modal"
            phx-value-proposal_ou_origin={@ou.ou_id}
            variant="secondary"
            icon="fa-solid fa-hand"
            size="lg"
          >
            Gobernar
          </.app_button>
          <.app_button
            phx-click="open_tree_navigator_modal"
            phx-target={@myself}
            variant="primary"
            icon="fa-solid fa-sitemap rotate-180"
            size="lg"
          >
            Navegar
          </.app_button>
        </div>
      </div>
    </div>
    """
  end

  def show_navigate(js \\ %JS{}) do
    js
    |> JS.toggle_class("hidden", to: "#dropdown")
  end

  @impl true
  def handle_event("open_tree_navigator_modal", _params, socket) do
    app_view = %AppView{
      view_id: "modal-tree_navigator",
      view_module: AuroraGov.Web.Live.Panel.TreeNavigator,
      view_options: %{
        modal_size: "quadruple_large"
      }
    }

    send(self(), {:open, :app_modal, app_view})

    {:noreply, socket}
  end
end
