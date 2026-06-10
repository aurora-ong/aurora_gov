defmodule AuroraGov.Web.Live.Panel.Home do
  # In Phoenix apps, the line is typically: use MyAppWeb, :live_component
  use AuroraGov.Web, :live_component

  def update(assigns, socket) do
    socket =
      socket
      |> assign(:app_context, assigns.app_context)
      |> assign(:page_title, "Inicio")
      |> assign(:ou, AuroraGov.Context.OUContext.get_ou(assigns.app_context.current_ou_id))

    show_activity_panel(assigns.app_context)

    {:ok, socket}
  end

  defp show_activity_panel(app_context) do
    app_panel = %AppView{
      view_id: "panel-activity",
      view_module: AuroraGov.Web.Live.Panel.Side.LastActivity,
      view_options: %{},
      view_params: %{
        app_context: app_context
      }
    }

    send(self(), {:open, :app_side_panel, app_panel})
  end

  def render(assigns) do
    ~H"""
    <div class="w-full h-full flex flex-col gap-6 p-4 md:p-6 overflow-y-auto">

           <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6 flex flex-col h-full">
          <div class="flex items-center gap-2 mb-4 border-b border-gray-100 pb-3">
            <i class="fa-solid fa-bullseye text-blue-500"></i>
            <h3 class="text-lg font-semibold text-gray-800">Objetivo</h3>
          </div>

          <p class="text-gray-600 text-base leading-relaxed flex-1">{@ou.ou_goal}</p>
        </div>

      <div class="grid grid-cols-1 md:grid-cols-1 gap-6 w-full">
        <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6 w-full">
          <div class="flex items-center justify-between mb-6 border-b border-gray-100 pb-3">
            <div class="flex items-center gap-2">
              <i class="fa-solid fa-id-badge text-indigo-500"></i>
              <h3 class="text-lg font-semibold text-gray-800">Roles</h3>
            </div>

            <button class="text-sm text-blue-600 hover:text-blue-800 font-medium transition-colors">
              Ver directorio completo &rarr;
            </button>
          </div>

          <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
            <div class="flex items-center gap-3 p-3 rounded-lg border border-transparent hover:border-indigo-100 hover:bg-indigo-50/50 transition-colors group cursor-pointer">
              <div class="w-12 h-12 rounded-full bg-gradient-to-br from-indigo-100 to-blue-100 flex items-center justify-center text-indigo-700 font-bold shadow-sm shrink-0 border border-indigo-200">
                MV
              </div>

              <div class="flex flex-col overflow-hidden">
                <span class="font-semibold text-gray-900 text-sm truncate group-hover:text-indigo-700 transition-colors">
                  María Valenzuela
                </span>
                <span class="text-xs text-gray-500 font-medium truncate">Coordinadora General</span>
              </div>
            </div>

            <div class="flex items-center gap-3 p-3 rounded-lg border border-transparent hover:border-indigo-100 hover:bg-indigo-50/50 transition-colors group cursor-pointer">
              <div class="w-12 h-12 rounded-full shadow-sm shrink-0 border border-gray-200 overflow-hidden bg-gray-100">
                <img
                  src="https://api.dicebear.com/7.x/notionists/svg?seed=Pavel&backgroundColor=e2e8f0"
                  alt="Avatar"
                  class="w-full h-full object-cover"
                />
              </div>

              <div class="flex flex-col overflow-hidden">
                <span class="font-semibold text-gray-900 text-sm truncate group-hover:text-indigo-700 transition-colors">
                  Pedro Recabarren
                </span>
                <span class="text-xs text-gray-500 font-medium truncate">Auditor Tecnológico</span>
              </div>
            </div>

            <div class="flex items-center gap-3 p-3 rounded-lg border border-transparent hover:border-indigo-100 hover:bg-indigo-50/50 transition-colors group cursor-pointer">
              <div class="w-12 h-12 rounded-full bg-gradient-to-br from-emerald-100 to-teal-100 flex items-center justify-center text-emerald-700 font-bold shadow-sm shrink-0 border border-emerald-200">
                CS
              </div>

              <div class="flex flex-col overflow-hidden">
                <span class="font-semibold text-gray-900 text-sm truncate group-hover:text-indigo-700 transition-colors">
                  Camila Soto
                </span> <span class="text-xs text-gray-500 font-medium truncate">Tesorera</span>
              </div>
            </div>

            <div class="flex items-center gap-3 p-3 rounded-lg border border-transparent hover:border-indigo-100 hover:bg-indigo-50/50 transition-colors group cursor-pointer">
              <div class="w-12 h-12 rounded-full shadow-sm shrink-0 border border-gray-200 overflow-hidden bg-gray-100">
                <img
                  src="https://api.dicebear.com/7.x/notionists/svg?seed=Andres&backgroundColor=e2e8f0"
                  alt="Avatar"
                  class="w-full h-full object-cover"
                />
              </div>

              <div class="flex flex-col overflow-hidden">
                <span class="font-semibold text-gray-900 text-sm truncate group-hover:text-indigo-700 transition-colors">
                  Andrés Silva
                </span>
                <span class="text-xs text-gray-500 font-medium truncate">Gestión Territorial</span>
              </div>
            </div>

            <%!-- <div class="flex items-center gap-3 p-3 rounded-lg border border-transparent hover:border-indigo-100 hover:bg-indigo-50/50 transition-colors group cursor-pointer">
              <div class="w-12 h-12 rounded-full bg-gradient-to-br from-purple-100 to-pink-100 flex items-center justify-center text-purple-700 font-bold shadow-sm shrink-0 border border-purple-200">
                RA
              </div>

              <div class="flex flex-col overflow-hidden">
                <span class="font-semibold text-gray-900 text-sm truncate group-hover:text-indigo-700 transition-colors">
                  Roberto Aránguiz
                </span> <span class="text-xs text-gray-500 font-medium truncate">Vocero</span>
              </div>
            </div> --%>

            <%!-- <div class="flex items-center gap-3 p-3 rounded-lg border border-transparent hover:border-indigo-100 hover:bg-indigo-50/50 transition-colors group cursor-pointer">
              <div class="w-12 h-12 rounded-full shadow-sm shrink-0 border border-gray-200 overflow-hidden bg-gray-100">
                <img
                  src="https://api.dicebear.com/7.x/notionists/svg?seed=Laura&backgroundColor=e2e8f0"
                  alt="Avatar"
                  class="w-full h-full object-cover"
                />
              </div>

              <div class="flex flex-col overflow-hidden">
                <span class="font-semibold text-gray-900 text-sm truncate group-hover:text-indigo-700 transition-colors">
                  Laura Gómez
                </span> <span class="text-xs text-gray-500 font-medium truncate">Comisión Ética</span>
              </div>
            </div> --%>
          </div>
        </div>



        <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6 flex flex-col h-full">
          <div class="flex items-center gap-2 mb-4 border-b border-gray-100 pb-3">
            <i class="fa-solid fa-align-left text-blue-500"></i>
            <h3 class="text-lg font-semibold text-gray-800">Descripción</h3>
          </div>

          <p class="text-gray-600 text-base leading-relaxed flex-1">{@ou.ou_description}</p>
        </div>
      </div>
    </div>
    """
  end
end
