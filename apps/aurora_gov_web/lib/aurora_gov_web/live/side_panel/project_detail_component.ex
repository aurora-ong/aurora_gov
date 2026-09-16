defmodule AuroraGov.Web.Live.Panel.Side.ProjectDetail do
  require Logger
  use AuroraGov.Web, :live_component
  alias AuroraGov.Context.ProjectContext

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:project, nil)
      |> assign(:tasks, [])
      |> assign(:active_tab, :metrics)
      |> assign(:loading, true)

    {:ok, socket}
  end

  @impl true
  def handle_event("set_tab", %{"tab" => tab_name}, socket) do
    tab = String.to_existing_atom(tab_name)
    {:noreply, assign(socket, :active_tab, tab)}
  end

  @impl true
  def update(%{update: {type, _data}}, socket) do
    socket =
      if type in [
           :project_updated,
           :task_created,
           :task_updated,
           :task_assigned,
           :task_completed,
           :task_abandoned,
           :task_cancelled
         ] do
        load_project_details(socket)
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
      |> assign(:project_id, assigns.project_id)
      |> load_project_details()

    {:ok, socket}
  end

  defp load_project_details(socket) do
    project_id = socket.assigns.project_id

    socket
    |> assign(:loading, true)
    |> start_async(:load_detail_data, fn ->
      project = ProjectContext.get_project(project_id)
      tasks = ProjectContext.list_project_tasks(project_id)

      {project, tasks}
    end)
  end

  @impl true
  def handle_async(:load_detail_data, {:ok, {project, tasks}}, socket) do
    socket =
      socket
      |> assign(:loading, false)
      |> assign(:project, project)
      |> assign(:tasks, tasks)

    {:noreply, socket}
  end

  @impl true
  def handle_async(:load_detail_data, result, socket) do
    Logger.warning("Error loading project detail data: #{inspect(result)}")

    socket =
      socket
      |> assign(:loading, false)
      |> put_flash(:error, "No se pudieron cargar los detalles del proyecto.")

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="w-full space-y-6">
      <%= if @loading or is_nil(@project) do %>
        <div class="w-full py-20 flex justify-center items-center">
          <.loading_spinner size="double_large" />
        </div>
      <% else %>
        <!-- Cabecera del Proyecto -->
        <div class="border-b border-gray-100 pb-6 mb-6">
          <div class="flex items-center gap-2 text-xs text-aurora_orange font-bold uppercase tracking-wider mb-2">
            <i class="fa-solid fa-briefcase"></i> Detalle de Proyecto
          </div>

          <div class="flex flex-col gap-2">
            <h2 class="text-2xl font-bold text-gray-900 flex items-center gap-2">
              <i class="fa-solid fa-folder-open text-yellow-500"></i> {@project.name}
            </h2>

            <div class="flex items-center gap-2">
              <.project_id_badge id={@project.project_id} />
              <.project_status_badge status={@project.status} />
            </div>
          </div>

          <p class="text-sm text-gray-500 mt-4">{@project.description}</p>

          <div class="mt-4 flex flex-wrap items-center gap-x-6 gap-y-2 text-xs text-gray-600 bg-gray-50 rounded-xl p-3">
            <div class="flex items-center gap-2">
              <button
                phx-click="open_proposal_create_modal"
                phx-value-proposal_ou_origin={@app_context.current_ou_id}
                phx-value-proposal_ou_end={@app_context.current_ou_id}
                phx-value-proposal_title={"Actualizar Proyecto: #{@project.name}"}
                phx-value-proposal_description={"Se propone actualizar la información general del proyecto #{@project.project_id}."}
                phx-value-proposal_power_id="org.project.update"
                phx-value-power-project_id={@project.project_id}
                phx-value-power-name={@project.name}
                phx-value-power-description={@project.description}
                class="px-2 py-1 text-blue-600 hover:bg-blue-50 rounded-lg transition-colors font-semibold flex items-center gap-1.5"
              >
                <i class="fa-solid fa-pen-to-square"></i> Actualizar
              </button>
              <button
                phx-click="open_proposal_create_modal"
                phx-value-proposal_ou_origin={@app_context.current_ou_id}
                phx-value-proposal_ou_end={@app_context.current_ou_id}
                phx-value-proposal_title={"Transferir Proyecto: #{@project.name}"}
                phx-value-proposal_description={"Se propone transferir la administración y fondos del proyecto #{@project.project_id} a otra unidad organizativa."}
                phx-value-proposal_power_id="org.project.transfer"
                phx-value-power-project_id={@project.project_id}
                class="px-2 py-1 text-violet-600 hover:bg-violet-50 rounded-lg transition-colors font-semibold flex items-center gap-1.5"
              >
                <i class="fa-solid fa-arrow-right-arrow-left"></i> Transferir
              </button>
              <button
                phx-click="open_proposal_create_modal"
                phx-value-proposal_ou_origin={@app_context.current_ou_id}
                phx-value-proposal_ou_end={@app_context.current_ou_id}
                phx-value-proposal_title={"Archivar Proyecto: #{@project.name}"}
                phx-value-proposal_description={"Se propone archivar el proyecto #{@project.project_id}. Todas sus tareas serán canceladas."}
                phx-value-proposal_power_id="org.project.archive"
                phx-value-power-project_id={@project.project_id}
                class="px-2 py-1 text-red-600 hover:bg-red-50 rounded-lg transition-colors font-semibold flex items-center gap-1.5"
              >
                <i class="fa-solid fa-box-archive"></i> Archivar
              </button>
            </div>

            <div class="flex items-center gap-3 ml-auto">
              <button
                phx-click="open_proposal_create_modal"
                phx-value-proposal_ou_origin={@app_context.current_ou_id}
                phx-value-proposal_ou_end={@app_context.current_ou_id}
                phx-value-proposal_title={"Nueva Tarea para: #{@project.name}"}
                phx-value-proposal_description="Se propone la creación de una nueva tarea en el backlog del proyecto."
                phx-value-proposal_power_id="org.task.create"
                phx-value-power-project_id={@project.project_id}
                class="px-3 py-1.5 bg-blue-50 text-blue-700 hover:bg-blue-100 rounded-lg transition-colors font-bold flex items-center gap-1.5"
              >
                <i class="fa-solid fa-list-check"></i> Añadir Tarea
              </button>
            </div>
          </div>
          <!-- Tabs Navigation -->
          <div class="mt-8 border-b border-gray-200">
            <nav class="-mb-px flex space-x-8" aria-label="Tabs">
              <button
                phx-click="set_tab"
                phx-value-tab="metrics"
                phx-target={@myself}
                class={
                  if @active_tab == :metrics,
                    do:
                      "border-aurora_orange text-aurora_orange whitespace-nowrap py-4 px-1 border-b-2 font-medium text-sm",
                    else:
                      "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300 whitespace-nowrap py-4 px-1 border-b-2 font-medium text-sm"
                }
              >
                <i class="fa-solid fa-chart-pie mr-2"></i>Métricas
              </button>
              <button
                phx-click="set_tab"
                phx-value-tab="tasks"
                phx-target={@myself}
                class={
                  if @active_tab == :tasks,
                    do:
                      "border-aurora_orange text-aurora_orange whitespace-nowrap py-4 px-1 border-b-2 font-medium text-sm",
                    else:
                      "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300 whitespace-nowrap py-4 px-1 border-b-2 font-medium text-sm"
                }
              >
                <i class="fa-solid fa-list-check mr-2"></i>Tareas ({length(@tasks)})
              </button>
            </nav>
          </div>

          <div class="mt-6">
            <%= if @active_tab == :metrics do %>
              <!-- Métricas del Proyecto -->
              <div class="pt-2">
                <h3 class="text-sm font-bold text-gray-700 uppercase tracking-wider mb-4 flex items-center gap-2">
                  <i class="fa-solid fa-chart-line text-gray-400"></i> Progreso de Tareas
                </h3>

                <div class="grid grid-cols-4 gap-4">
                  <div class="p-4 border border-gray-200 rounded-lg bg-white shadow-sm flex flex-col items-center justify-center">
                    <div class="text-3xl font-black text-gray-800 mb-1">{length(@tasks)}</div>

                    <div class="text-[10px] uppercase font-bold text-gray-400 tracking-wider mt-1 text-center">
                      Tareas Totales
                    </div>
                  </div>

                  <div class="p-4 border border-gray-200 rounded-lg bg-white shadow-sm flex flex-col items-center justify-center">
                    <div class="text-3xl font-black text-aurora_orange mb-1">
                      {Enum.count(@tasks, fn t -> t.status == :in_progress end)}
                    </div>

                    <div class="text-[10px] uppercase font-bold text-gray-400 tracking-wider mt-1 text-center">
                      En Progreso
                    </div>
                  </div>

                  <div class="p-4 border border-gray-200 rounded-lg bg-white shadow-sm flex flex-col items-center justify-center">
                    <div class="text-3xl font-black text-emerald-600 mb-1">
                      {Enum.count(@tasks, fn t -> t.status == :completed end)}
                    </div>

                    <div class="text-[10px] uppercase font-bold text-emerald-600/70 tracking-wider mt-1 text-center">
                      Completadas
                    </div>
                  </div>

                  <div class="p-4 border border-gray-200 rounded-lg bg-white shadow-sm flex flex-col items-center justify-center">
                    <div class="text-3xl font-black text-purple-600 mb-1">
                      {Enum.count(@tasks, fn t -> t.status == :backlog end)}
                    </div>

                    <div class="text-[10px] uppercase font-bold text-purple-600/70 tracking-wider mt-1 text-center">
                      Sin Asignar (Backlog)
                    </div>
                  </div>
                </div>
              </div>
            <% end %>

            <%= if @active_tab == :tasks do %>
              <!-- Listado de Tareas -->
              <div class="space-y-4 pt-2">
                <%= for task <- @tasks do %>
                  <.link
                    patch={~p"/app/tasks/#{task.task_id}?context=#{@app_context.current_ou_id}"}
                    class="block bg-white border border-gray-200 rounded-xl p-4 hover:border-aurora_orange hover:shadow-md transition-all group"
                  >
                    <div class="flex justify-between items-start">
                      <div class="flex items-start gap-3 w-full">
                        <div class="mt-1 bg-gray-50 p-2 rounded-lg text-gray-400 group-hover:text-aurora_orange group-hover:bg-orange-50 transition-colors">
                          <i class="fa-solid fa-check-square"></i>
                        </div>

                        <div class="flex-1">
                          <div class="flex justify-between items-start">
                            <h4 class="text-sm font-bold text-gray-900">{task.name}</h4>

                            <div class="flex items-center gap-2">
                              <.task_id_badge id={task.task_id} />
                              <.task_status_badge status={task.status} />
                            </div>
                          </div>

                          <p class="text-xs font-semibold text-gray-700 mt-2 line-clamp-2">
                            {task.goal}
                          </p>

                          <div class="flex items-center gap-4 mt-4 text-[10px] text-gray-400 font-mono">
                            <span class="flex items-center gap-1 font-sans">
                              <i class="fa-solid fa-calendar-plus"></i> {Calendar.strftime(
                                task.created_at,
                                "%d/%m/%Y"
                              )}
                            </span>
                            <span class="flex items-center gap-1 font-sans">
                              <i class="fa-solid fa-clock"></i> {Calendar.strftime(
                                task.updated_at,
                                "%d/%m/%Y"
                              )}
                            </span>
                          </div>
                        </div>
                      </div>
                    </div>
                  </.link>
                <% end %>

                <%= if Enum.empty?(@tasks) do %>
                  <div class="text-center py-10 bg-gray-50 rounded-xl border-2 border-dashed border-gray-200">
                    <i class="fa-solid fa-clipboard-list text-3xl text-gray-300 mb-3"></i>
                    <p class="text-sm text-gray-500">
                      Este proyecto no tiene tareas registradas aún.
                    </p>
                  </div>
                <% end %>
              </div>
            <% end %>
          </div>
        </div>
      <% end %>
    </div>
    """
  end
end
