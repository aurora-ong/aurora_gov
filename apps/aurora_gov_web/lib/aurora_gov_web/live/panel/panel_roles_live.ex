defmodule AuroraGov.Web.Live.Panel.Roles do
  require Logger
  use AuroraGov.Web, :live_component
  alias AuroraGov.Context.RoleContext

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:filter, "active")
      |> assign(current_page: 1, total_pages: 0, total_count: 0)
      |> assign(:sort_by, :created_at)
      |> assign(:sort_order, :desc)
      |> assign(:assignments, %{})
      |> stream_configure(:role_list, dom_id: &"role-#{&1.role_id}")
      |> stream(:role_list, [])

    {:ok, socket}
  end

  @impl true
  def update(%{role_event: {type, data}}, socket) do
    current_ou = socket.assigns.app_context.current_ou_id

    socket =
      if data.ou_id == current_ou do
        case type do
          :role_created ->
            socket |> stream_insert(:role_list, data, at: 0)

          :role_archived ->
            if socket.assigns.filter == "all" do
              load_roles(socket)
            else
              socket |> stream_delete(:role_list, data)
            end

          _ ->
            # Refresh all assignments for simplicity if assigned/unassigned
            load_assignments(socket)
        end
      else
        socket
      end

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(:app_context, assigns.app_context)
      |> load_roles()
      |> load_assignments()

    {:ok, socket}
  end

  defp load_roles(socket) do
    ou_id = socket.assigns.app_context.current_ou_id

    params = %{
      "page" => socket.assigns.current_page,
      "order_by" => [socket.assigns.sort_by],
      "order_directions" => [socket.assigns.sort_order],
      "status" => socket.assigns[:filter] || "active"
    }

    socket
    |> assign(:loading, true)
    |> start_async(:load_roles_data, fn ->
      RoleContext.list_roles_by_ou(ou_id, params)
    end)
  end

  defp load_assignments(socket) do
    ou_id = socket.assigns.app_context.current_ou_id
    assignments = RoleContext.list_assignments_by_ou(ou_id)

    # Group by role_id, keeping the whole assignment struct
    grouped = Enum.group_by(assignments, & &1.role_id)
    assign(socket, :assignments, grouped)
  end

  @impl true
  def handle_async(:load_roles_data, {:ok, {:ok, {roles, meta}}}, socket) do
    socket =
      socket
      |> assign(:loading, false)
      |> assign(:current_page, meta.current_page)
      |> assign(:total_pages, meta.total_pages)
      |> assign(:total_count, meta.total_count)
      |> stream(:role_list, roles, reset: true)

    {:noreply, socket}
  end

  def handle_async(:load_roles_data, result, socket) do
    Logger.warning("Error al cargar roles: #{inspect(result)}")

    socket =
      socket
      |> assign(:loading, false)
      |> put_flash(:error, "No se pudieron cargar los roles.")

    {:noreply, socket}
  end

  @impl true
  def handle_event("update_filter", %{"filter" => filter}, socket) do
    {:noreply,
     socket
     |> assign(:filter, filter)
     |> assign(:current_page, 1)
     |> load_roles()}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="w-full h-full p-6">
      <div class="flex w-full h-12 flex-row justify-between mb-5 items-center">
        <div class="flex flex-row items-center gap-6">
          <.filter_button_group
            options={[
              %{label: "Todos", value: "all"},
              %{label: "Activos", value: "active"},
              %{label: "Inactivos", value: "archived"}
            ]}
            selected={@filter}
            on_select="update_filter"
            phx_target={@myself}
          />
        </div>
        <div class="flex flex-row gap-3">
          <button
            phx-click="open_proposal_create_modal"
            phx-value-proposal_ou_origin={@app_context.current_ou_id}
            phx-value-proposal_ou_end={@app_context.current_ou_id}
            phx-value-proposal_power_id="org.role.create"
            class="justify-center items-center text-lg primary"
          >
            <i class="fa-solid fa-plus text-xl"></i> Nuevo rol
          </button>
        </div>
      </div>

      <div class="w-full">
        <.table
          id="roles-table"
          rows={@streams.role_list}
          page={@current_page}
          loading={@loading}
          total_pages={@total_pages}
          total_count={@total_count}
          target={@myself}
        >
          <:empty_state>
            <div class="flex flex-col items-center justify-center py-4">
              <i class="fa-solid fa-id-card-clip text-4xl text-gray-300 mb-3"></i>
              <h3 class="text-lg font-medium text-gray-900">No se encontraron roles</h3>
            </div>
          </:empty_state>

          <:col :let={role} label="Nombre" field={:role_name}>
            {role.role_name}
          </:col>

          <:col :let={role} label="Descripción" field={:role_description}>
            {role.role_description}
          </:col>

          <:col :let={role} label="Estado" align="center" field={:status}>
            <span class={"inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium " <>
              if(role.status == "active", do: "bg-green-100 text-green-800", else: "bg-gray-100 text-gray-800")}>
              {if(role.status == "active", do: "Activo", else: "Archivado")}
            </span>
          </:col>

          <:col :let={role} label="Asignaciones" align="left">
            <div class="flex flex-wrap gap-3">
              <%= for assignment <- Map.get(@assignments, role.role_id, []) do %>
                <div class="flex items-center gap-2 p-1.5 pr-3 rounded-full border border-gray-200 bg-gray-50 hover:bg-white hover:shadow-sm transition-all group">
                  <div class="w-8 h-8 rounded-full overflow-hidden shrink-0 border border-gray-200 bg-white">
                    <img
                      src={"https://api.dicebear.com/7.x/notionists/svg?seed=#{assignment.person_id}&backgroundColor=e2e8f0"}
                      alt="Avatar"
                      class="w-full h-full object-cover"
                    />
                  </div>
                  <div class="flex flex-col">
                    <span class="text-xs font-bold text-gray-900 leading-tight">
                      {assignment.person.person_name}
                    </span>
                    <span class="text-[10px] text-gray-500 leading-tight">
                      {assignment.person_id}
                    </span>
                  </div>
                </div>
              <% end %>
              <%= if Map.get(@assignments, role.role_id, []) == [] do %>
                 <span class="text-xs text-gray-400 italic">Sin asignaciones</span>
              <% end %>
            </div>
          </:col>

          <:action :let={role}>
            <%= if role.status == "active" do %>
              <button
                phx-click="open_proposal_create_modal"
                phx-value-proposal_ou_origin={@app_context.current_ou_id}
                phx-value-proposal_ou_end={@app_context.current_ou_id}
                phx-value-proposal_power_id="org.role.assign"
                phx-value-power-role_id={role.role_id}
                class="text-blue-600 hover:text-blue-900 mr-2"
                title="Asignar"
              >
                <i class="fa-solid fa-user-plus"></i>
              </button>

              <button
                phx-click="open_proposal_create_modal"
                phx-value-proposal_ou_origin={@app_context.current_ou_id}
                phx-value-proposal_ou_end={@app_context.current_ou_id}
                phx-value-proposal_power_id="org.role.archive"
                phx-value-power-role_id={role.role_id}
                class="text-red-600 hover:text-red-900"
                title="Archivar"
              >
                <i class="fa-solid fa-box-archive"></i>
              </button>
            <% else %>
              <span class="text-xs text-gray-400 italic">Archivado</span>
            <% end %>
          </:action>
        </.table>
      </div>
    </div>
    """
  end
end
