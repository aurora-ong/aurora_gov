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
      |> assign(:ou, AuroraGov.Context.OUContext.get_ou_by_id(assigns.app_context.current_ou_id))

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="w-full bg-white rounded-xl h-fit shadow-sm border border-gray-200 relative group transition px-5 py-4">
      <div class="absolute top-0 left-0 w-full h-2 rounded-xl rounded-b-none transition bg-aurora_blue_light ">
      </div>

      <div class="flex flex-col md:flex-row justify-between items-start md:items-center gap-4 mt-2">
        <h1 class="text-3xl md:text-4xl font-bold text-gray-900 flex items-center gap-3">
          <div class="w-12 h-12 rounded-lg bg-blue-50 flex items-center justify-center text-aurora_orange shadow-sm border border-blue-100 shrink-0">
            <i class="fa-solid fa-users text-xl"></i>
          </div>
           <span class="truncate">{@ou.ou_name}</span>
        </h1>

        <div class="flex flex-row gap-3 items-center justify-center h-full">
          <button
            phx-click="open_proposal_create_modal"
            phx-value-proposal_ou_origin={@ou.ou_id}
            class="text-lg primary outlined"
          >
            <i class="fa-solid fa-hand text-xl"></i> Gobernar
          </button>
          <button
            phx-click="open_tree_navigator_modal"
            phx-target={@myself}
            class="text-lg primary outlined"
          >
            <i class="fa-solid fa-sitemap text-xl rotate-180"></i> Navegar
          </button>
        </div>
      </div>

      <div class="mt-6 pt-4 border-t border-gray-200 flex flex-wrap items-center justify-between gap-y-4 gap-x-6">
        <div class="flex flex-wrap items-center gap-3">
          <.link
            patch={~p"/app/home?context=#{@ou.ou_id}"}
            replace
            class="group flex items-center gap-2 px-3 py-1.5 bg-white hover:bg-gray-50 border border-gray-200 hover:border-gray-300 rounded-lg shadow-sm transition-all duration-200 cursor-pointer"
          >
            <i class="fa-solid fa-sitemap rotate-180 text-gray-400 group-hover:text-gray-600 transition-colors">
            </i>
            <span class="font-mono text-xs font-semibold text-gray-600 group-hover:text-gray-900">
              {@ou.ou_id}
            </span>
          </.link>
          <div class="hidden sm:block h-5 w-px bg-gray-200 mx-1"></div>

          <.link
            patch={~p"/app/members?context=#{@ou.ou_id}"}
            replace
            class="group flex items-center gap-2 px-3 py-1.5 bg-white hover:bg-gray-50 border border-gray-200 hover:border-gray-300 rounded-lg shadow-sm transition-all duration-200 cursor-pointer"
          >
            <span class="text-xs font-bold text-blue-700 bg-blue-50 px-2 py-0.5 rounded-full border border-blue-100 group-hover:bg-blue-100 transition-colors">
              {AuroraGov.Context.MembershipContext.count_active_memberships_by_ou(@ou.ou_id)}
            </span>
            <span class="text-sm text-gray-500 group-hover:text-gray-700">Miembros activos</span>
          </.link>
          <.link
            patch={~p"/app/proposals?context=#{@ou.ou_id}"}
            replace
            class="group flex items-center gap-2 px-3 py-1.5 bg-white hover:bg-gray-50 border border-gray-200 hover:border-gray-300 rounded-lg shadow-sm transition-all duration-200 cursor-pointer"
          >
            <span class="text-xs font-bold text-purple-700 bg-purple-50 px-2 py-0.5 rounded-full border border-purple-100 group-hover:bg-purple-100 transition-colors">
              {AuroraGov.Context.ProposalContext.count_active_proposals_by_ou(@ou.ou_id)}
            </span>
            <span class="text-sm text-gray-500 group-hover:text-gray-700">Propuestas activas</span>
          </.link>
          <button
            type="button"
            class="group flex items-center gap-2 px-3 py-1.5 bg-white hover:bg-gray-50 border border-gray-200 hover:border-gray-300 rounded-lg shadow-sm transition-all duration-200 cursor-pointer"
          >
            <span class="text-xs font-bold text-orange-700 bg-orange-50 px-2 py-0.5 rounded-full border border-orange-100 group-hover:bg-orange-100 transition-colors">
              0
            </span>
            <span class="text-sm text-gray-500 group-hover:text-gray-700">Tareas activas</span>
          </button>
        </div>

        <div
          class="flex items-center gap-1.5 text-xs text-gray-400 ml-auto"
          title="Fecha de fundación"
        >
          <i class="fa-regular fa-calendar font-light"></i>
          <span>Fundada el {@ou.created_at |> Calendar.strftime("%d/%m/%Y")}</span>
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
