defmodule AuroraGov.Web.Live.Panel.Projects do
  require Logger
  use AuroraGov.Web, :live_component
  alias AuroraGov.Context.ProjectContext

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:projects, [])
      |> assign(:filter, "all")
      |> assign(:loading, true)

    {:ok, socket}
  end

  @impl true
  def update(%{project_event: {type, _data}}, socket) do
    # When any project event occurs, reload the project list to reflect changes
    socket =
      if type in [:project_created, :project_renamed, :project_archived, :project_transferred] do
        load_projects(socket)
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
      |> load_projects()

    {:ok, socket}
  end

  @impl true
  def handle_event("update_filter", %{"filter" => filter}, socket) do
    {:noreply, assign(socket, :filter, filter)}
  end

  defp load_projects(socket) do
    ou_id = socket.assigns.app_context.current_ou_id

    socket
    |> assign(:loading, true)
    |> start_async(:load_projects_data, fn ->
      ProjectContext.list_projects(ou_id)
    end)
  end

  @impl true
  def handle_async(:load_projects_data, {:ok, projects}, socket) do
    socket =
      socket
      |> assign(:loading, false)
      |> assign(:projects, projects)

    {:noreply, socket}
  end

  def handle_async(:load_projects_data, result, socket) do
    Logger.warning("Error loading projects: #{inspect(result)}")

    socket =
      socket
      |> assign(:loading, false)
      |> put_flash(:error, "No se pudieron cargar los proyectos.")

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    filtered_projects = filter_projects(assigns.projects, assigns.filter)
    assigns = assign(assigns, :filtered_projects, filtered_projects)

    ~H"""
    <div class="w-full h-full">
      <div class="flex w-full min-h-12 flex-row justify-between items-center gap-3 mb-5">
        <.filter_button_group
          options={[
            %{label: "Todos", value: "all"},
            %{label: "Activos", value: "active"},
            %{label: "Archivados", value: "archived"}
          ]}
          selected={@filter}
          on_select="update_filter"
          phx_target={@myself}
        />
        <div class="flex flex-row items-center gap-2 sm:gap-3 shrink-0">
          <.action_dropdown id="projects-actions">
            <:item
              icon="fa-solid fa-plus"
              label="Nuevo Proyecto"
              proposal_ou_origin={@app_context.current_ou_id}
              proposal_ou_end={@app_context.current_ou_id}
              proposal_power_id="org.project.create"
            />
          </.action_dropdown>
        </div>
      </div>

      <%= if @loading do %>
        <div class="w-full py-20 flex justify-center items-center">
          <.loading_spinner size="double_large" />
        </div>
      <% else %>
        <%= if Enum.empty?(@filtered_projects) do %>
          <div class="flex flex-col items-center justify-center py-20 bg-gray-50 rounded-2xl border-2 border-dashed border-gray-200">
            <i class="fa-solid fa-briefcase text-5xl text-gray-300 mb-4"></i>
            <h3 class="text-lg font-semibold text-gray-700">No se encontraron proyectos</h3>
            <p class="text-sm text-gray-400 mt-1 mb-6">Crea una propuesta de gobernanza para iniciar un proyecto.</p>
          </div>
        <% else %>
          <div class="flex flex-col gap-6">
            <%= for project <- @filtered_projects do %>
              <div class="flex flex-col bg-white rounded-2xl border border-gray-100 shadow-sm hover:shadow-md transition-all duration-200 overflow-hidden">
                <div class="p-6 flex-1 flex flex-col">
                  <.link
                    patch={~p"/app/projects/#{project.project_id}?context=#{@app_context.current_ou_id}"}
                    class="block hover:text-aurora_orange group mb-2"
                  >
                    <h3 class="text-lg font-bold text-gray-900 group-hover:text-aurora_orange transition-colors flex items-center gap-2">
                      <i class="fa-solid fa-folder text-yellow-500"></i>
                      {project.name}
                    </h3>
                  </.link>

                  <div class="flex items-center gap-2">
                    <.project_id_badge id={project.project_id} />
                    <.project_status_badge status={project.status} />
                  </div>

                  <p class="text-sm text-gray-600 mt-2 line-clamp-2">
                    {project.description}
                  </p>

                  <div class="mt-4 flex gap-4">
                    <div class="flex items-center gap-2 bg-gray-50 px-3 py-1.5 rounded-lg border border-gray-100">
                      <div class="text-xs font-bold text-gray-500 uppercase tracking-wider">Tareas Totales</div>
                      <div class="text-sm font-black text-gray-800">{length(project.tasks)}</div>
                    </div>
                    <div class="flex items-center gap-2 bg-orange-50 px-3 py-1.5 rounded-lg border border-orange-100">
                      <div class="text-xs font-bold text-aurora_orange uppercase tracking-wider">Activas</div>
                      <div class="text-sm font-black text-aurora_orange">{Enum.count(project.tasks, fn t -> t.status == :in_progress end)}</div>
                    </div>
                  </div>
                </div>
              </div>
            <% end %>
          </div>
        <% end %>
      <% end %>
    </div>
    """
  end

  defp filter_projects(projects, "all"), do: projects

  defp filter_projects(projects, status) do
    Enum.filter(projects, fn p -> to_string(p.status) == status end)
  end
end
