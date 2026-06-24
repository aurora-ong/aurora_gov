defmodule AuroraGov.Web.Live.Panel.Home do
  # In Phoenix apps, the line is typically: use MyAppWeb, :live_component
  use AuroraGov.Web, :live_component

  def update(assigns, socket) do
    ou_id = assigns.app_context.current_ou_id

    # Load roles and assignments
    roles =
      case AuroraGov.Context.RoleContext.list_roles_by_ou(ou_id, %{"page_size" => 100}) do
        {:ok, {roles, _meta}} -> roles
        _ -> []
      end

    assignments = AuroraGov.Context.RoleContext.list_assignments_by_ou(ou_id)
    grouped_assignments = Enum.group_by(assignments, & &1.role_id)

    socket =
      socket
      |> assign(:app_context, assigns.app_context)
      |> assign(:page_title, "Inicio")
      |> assign(:ou, AuroraGov.Context.OUContext.get_ou(ou_id))
      |> assign(:roles, roles)
      |> assign(:assignments, grouped_assignments)

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

            <.link
              patch={~p"/app/roles?context=#{@app_context.current_ou_id}"}
              class="text-sm text-blue-600 hover:text-blue-800 font-medium transition-colors"
              replace
            >
              Ver todos los roles
            </.link>
          </div>

          <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
            <%= for role <- @roles do %>
              <%= for assignment <- Map.get(@assignments, role.role_id, []) do %>
                <div class="flex items-center gap-3 p-3 rounded-lg border border-transparent hover:border-indigo-100 hover:bg-indigo-50/50 transition-colors group cursor-pointer">
                  <div class="w-12 h-12 rounded-full shadow-sm shrink-0 border border-gray-200 overflow-hidden bg-gray-100">
                    <img
                      src={"https://api.dicebear.com/7.x/notionists/svg?seed=#{assignment.person_id}&backgroundColor=e2e8f0"}
                      alt="Avatar"
                      class="w-full h-full object-cover"
                    />
                  </div>

                  <div class="flex flex-col overflow-hidden">
                    <span class="font-semibold text-gray-900 text-sm truncate group-hover:text-indigo-700 transition-colors">
                      {assignment.person.person_name}
                    </span>
                    <span class="text-xs text-gray-500 font-medium truncate">{role.role_name}</span>
                  </div>
                </div>
              <% end %>
            <% end %>

            <%= if Enum.empty?(@roles) or Enum.all?(@roles, fn r -> Map.get(@assignments, r.role_id, []) == [] end) do %>
              <div class="col-span-full flex flex-col items-center justify-center py-6 text-gray-400">
                <i class="fa-solid fa-id-badge text-3xl mb-2"></i>
                <span class="text-sm">No hay roles asignados actualmente</span>
              </div>
            <% end %>
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
