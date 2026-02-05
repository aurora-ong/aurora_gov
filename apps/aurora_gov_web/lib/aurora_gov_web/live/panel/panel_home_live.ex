defmodule AuroraGov.Web.Live.Panel.Home do
  # In Phoenix apps, the line is typically: use MyAppWeb, :live_component
  use AuroraGov.Web, :live_component

  def update(assigns, socket) do
    socket =
      socket
      |> assign(:app_context, assigns.app_context)
      |> assign(:page_title, "Inicio")
      |> assign(:ou, AuroraGov.Context.OUContext.get_ou_by_id(assigns.app_context.current_ou_id))

    show_activity_panel()

    {:ok, socket}
  end

  defp show_activity_panel() do
    app_panel = %AppView{
      view_id: "panel-activity",
      view_module: AuroraGov.Web.Live.Panel.Side.LastActivity,
      view_options: %{},
      view_params: %{}
    }

    send(self(), {:open, :app_side_panel, app_panel})
  end

  def render(assigns) do
    ~H"""
    <div class="w-full h-full flex flex-nowrap">
      <div class="flex flex-col items-center justify-center py-10 bg-gradient-to-r from-blue-100 to-white rounded-lg shadow-lg mb-6 gap-3 h-full w-full">
        <h1 class="text-4xl font-bold mb-2 flex items-center gap-2">
          <span class="ml-2 items-center gap-1 block">
            {@ou.ou_name}
          </span>
        </h1>

        <div class="max-w-2xl bg-white bg-opacity-80 rounded p-6 shadow">
          <h3 class="text-2xl font-semibold text-blue-700 mb-2">Descripción</h3>

          <p class="text-gray-800 text-base">
            {@ou.ou_description}
          </p>
        </div>

        <div class="max-w-2xl bg-white bg-opacity-80 rounded p-6 shadow">
          <h3 class="text-2xl font-semibold text-blue-700 mb-2">Objetivo</h3>

          <p class="text-gray-800 text-base">
            {@ou.ou_goal}
          </p>
        </div>

        <div class="max-w-2xl w-full bg-white bg-opacity-80 rounded p-6 shadow">
          <h3 class="text-2xl font-semibold text-blue-700 mb-2">
            Fundada el
            <span class="font-semibold">{@ou.created_at |> Calendar.strftime("%d/%m/%Y")}</span>
          </h3>
        </div>
      </div>
    </div>
    """
  end
end
