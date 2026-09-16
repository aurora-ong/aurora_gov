defmodule AuroraGov.Web.Live.Panel.Side.TaskDetail do
  require Logger
  use AuroraGov.Web, :live_component
  alias AuroraGov.Context.ProjectContext

  @impl true
  def mount(socket) do
    {:ok, assign(socket, :task, nil) |> assign(:loading, true) |> assign(:active_tab, "general")}
  end

  @impl true
  def handle_event("set_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, :active_tab, tab)}
  end

  @impl true
  def update(%{update: {type, _data}}, socket) do
    socket =
      if type in [
           :task_updated,
           :task_assigned,
           :task_completed,
           :task_abandoned,
           :task_cancelled,
           :task_evaluated
         ] do
        load_task_details(socket)
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
      |> assign(:task_id, assigns.task_id)
      |> load_task_details()

    {:ok, socket}
  end

  defp load_task_details(socket) do
    task_id = socket.assigns.task_id
    ou_id = socket.assigns.app_context.current_ou_id

    socket
    |> assign(:loading, true)
    |> start_async(:load_detail_data, fn ->
      task = ProjectContext.get_task(task_id)

      person =
        if task && task.person_id do
          AuroraGov.Context.PersonContext.get_person(task.person_id)
        else
          nil
        end

      events =
        case AuroraGov.EventStore.read_stream_forward(ou_id) do
          {:ok, stream_events} ->
            stream_events
            |> Enum.filter(fn e ->
              String.contains?(e.event_type, "Task") and Map.get(e.data, :task_id) == task_id
            end)
            |> Enum.reverse()

          _ ->
            []
        end

      {task, person, events}
    end)
  end

  @impl true
  def handle_async(:load_detail_data, {:ok, {task, person, events}}, socket) do
    socket =
      socket
      |> assign(:loading, false)
      |> assign(:task, task)
      |> assign(:assigned_person, person)
      |> assign(:task_events, events)

    {:noreply, socket}
  end

  @impl true
  def handle_async(:load_detail_data, result, socket) do
    Logger.warning("Error loading task detail data: #{inspect(result)}")

    socket =
      socket
      |> assign(:loading, false)
      |> put_flash(:error, "No se pudieron cargar los detalles de la tarea.")

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="w-full space-y-6">
      <%= if @loading or is_nil(@task) do %>
        <div class="w-full py-20 flex justify-center items-center">
          <.loading_spinner size="double_large" />
        </div>
      <% else %>
        <div class="border-b border-gray-100 pb-6 mb-6">
          <div class="flex items-center gap-2 text-xs text-aurora_orange font-bold uppercase tracking-wider mb-2">
            <i class="fa-solid fa-list-check"></i> Detalle de Tarea
          </div>
          
          <div class="flex flex-col gap-2">
            <h2 class="text-2xl font-bold text-gray-900">{@task.name}</h2>
            
            <div class="flex items-center gap-2">
              <.task_id_badge id={@task.task_id} /> <.task_status_badge status={@task.status} />
            </div>
          </div>
          
          <%= if @task.status not in [:completed, :cancelled] do %>
            <div class="mt-4 flex flex-wrap items-center gap-2 text-xs text-gray-600 bg-gray-50 rounded-xl p-3 border border-gray-100">
              <button
                phx-click="open_proposal_create_modal"
                phx-value-proposal_ou_origin={@app_context.current_ou_id}
                phx-value-proposal_ou_end={@app_context.current_ou_id}
                phx-value-proposal_title={"Actualizar Tarea: #{@task.name}"}
                phx-value-proposal_description={"Se propone actualizar los detalles de la tarea #{@task.task_id}."}
                phx-value-proposal_power_id="org.task.update"
                phx-value-power-project_id={@task.project_id}
                phx-value-power-task_id={@task.task_id}
                phx-value-power-name={@task.name}
                phx-value-power-description={@task.description}
                phx-value-power-goal={@task.goal}
                class="px-2 py-1 text-blue-600 hover:bg-blue-50 rounded-lg font-semibold flex gap-1 items-center transition-colors"
              >
                <i class="fa-solid fa-pen"></i> Actualizar
              </button>
              <button
                phx-click="open_proposal_create_modal"
                phx-value-proposal_ou_origin={@app_context.current_ou_id}
                phx-value-proposal_ou_end={@app_context.current_ou_id}
                phx-value-proposal_title={"Asignar Tarea: #{@task.name}"}
                phx-value-proposal_description={"Se propone asignar un responsable para la tarea #{@task.task_id}."}
                phx-value-proposal_power_id="org.task.assign"
                phx-value-power-project_id={@task.project_id}
                phx-value-power-task_id={@task.task_id}
                class="px-2 py-1 text-emerald-600 hover:bg-emerald-50 rounded-lg font-semibold flex gap-1 items-center transition-colors"
              >
                <i class="fa-solid fa-user-plus"></i> Asignar
              </button>
              <button
                phx-click="open_proposal_create_modal"
                phx-value-proposal_ou_origin={@app_context.current_ou_id}
                phx-value-proposal_ou_end={@app_context.current_ou_id}
                phx-value-proposal_title={"Completar Tarea: #{@task.name}"}
                phx-value-proposal_description={"Se propone dar por terminada la tarea #{@task.task_id} porque ya se cumplió el objetivo: #{@task.goal}."}
                phx-value-proposal_power_id="org.task.complete"
                phx-value-power-project_id={@task.project_id}
                phx-value-power-task_id={@task.task_id}
                class="px-2 py-1 text-purple-600 hover:bg-purple-50 rounded-lg font-semibold flex gap-1 items-center transition-colors"
              >
                <i class="fa-solid fa-check"></i> Completar
              </button>
              <button
                phx-click="open_proposal_create_modal"
                phx-value-proposal_ou_origin={@app_context.current_ou_id}
                phx-value-proposal_ou_end={@app_context.current_ou_id}
                phx-value-proposal_title={"Abandonar Tarea: #{@task.name}"}
                phx-value-proposal_description={"Se propone que la tarea #{@task.task_id} vuelva al backlog y quede sin responsable asignado."}
                phx-value-proposal_power_id="org.task.abandon"
                phx-value-power-project_id={@task.project_id}
                phx-value-power-task_id={@task.task_id}
                class="px-2 py-1 text-amber-600 hover:bg-amber-50 rounded-lg font-semibold flex gap-1 items-center transition-colors"
              >
                <i class="fa-solid fa-user-xmark"></i> Abandonar
              </button>
              <button
                phx-click="open_proposal_create_modal"
                phx-value-proposal_ou_origin={@app_context.current_ou_id}
                phx-value-proposal_ou_end={@app_context.current_ou_id}
                phx-value-proposal_title={"Anular Tarea: #{@task.name}"}
                phx-value-proposal_description={"Se propone cancelar de forma definitiva la tarea #{@task.task_id}."}
                phx-value-proposal_power_id="org.task.cancel"
                phx-value-power-project_id={@task.project_id}
                phx-value-power-task_id={@task.task_id}
                class="px-2 py-1 text-red-600 hover:bg-red-50 rounded-lg font-semibold flex gap-1 items-center transition-colors"
              >
                <i class="fa-solid fa-ban"></i> Anular
              </button>
            </div>
          <% end %>
          <!-- Tabs Navigation -->
          <div class="mt-6 border-b border-gray-200">
            <nav class="-mb-px flex space-x-8" aria-label="Tabs">
              <button
                phx-click="set_tab"
                phx-value-tab="general"
                phx-target={@myself}
                class={
                  if @active_tab == "general",
                    do:
                      "border-aurora_orange text-aurora_orange whitespace-nowrap py-4 px-1 border-b-2 font-medium text-sm",
                    else:
                      "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300 whitespace-nowrap py-4 px-1 border-b-2 font-medium text-sm"
                }
              >
                <i class="fa-solid fa-circle-info mr-2"></i>Información
              </button>
              <button
                phx-click="set_tab"
                phx-value-tab="history"
                phx-target={@myself}
                class={
                  if @active_tab == "history",
                    do:
                      "border-aurora_orange text-aurora_orange whitespace-nowrap py-4 px-1 border-b-2 font-medium text-sm",
                    else:
                      "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300 whitespace-nowrap py-4 px-1 border-b-2 font-medium text-sm"
                }
              >
                <i class="fa-solid fa-clock-rotate-left mr-2"></i>Historial
              </button>
              <button
                phx-click="set_tab"
                phx-value-tab="evaluation"
                phx-target={@myself}
                class={
                  if @active_tab == "evaluation",
                    do:
                      "border-aurora_orange text-aurora_orange whitespace-nowrap py-4 px-1 border-b-2 font-medium text-sm",
                    else:
                      "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300 whitespace-nowrap py-4 px-1 border-b-2 font-medium text-sm"
                }
              >
                <i class="fa-solid fa-star-half-stroke mr-2"></i>Evaluación
              </button>
            </nav>
          </div>
        </div>
        
        <div class="mt-6">
          <%= if @active_tab == "general" do %>
            <div class="space-y-6">
              <div>
                <h3 class="text-xs font-bold text-gray-400 uppercase tracking-wider mb-2">
                  Objetivo
                </h3>
                
                <p class="text-sm font-semibold text-gray-800">
                  <i class="fa-solid fa-bullseye text-aurora_orange mr-1"></i> {@task.goal}
                </p>
              </div>
              
              <div>
                <h3 class="text-xs font-bold text-gray-400 uppercase tracking-wider mb-2">
                  Descripción
                </h3>
                
                <p class="text-sm text-gray-600 bg-gray-50 p-4 rounded-xl border border-gray-100">
                  {@task.description}
                </p>
              </div>
              
              <div class="flex flex-wrap items-center gap-6 pt-4 border-t border-gray-100">
                <%= if @assigned_person do %>
                  <div>
                    <h3 class="text-xs font-bold text-gray-400 uppercase tracking-wider mb-2">
                      Asignado a
                    </h3>
                    
                    <span class="bg-blue-50 px-3 py-1.5 rounded-lg text-sm font-semibold text-blue-700 flex items-center gap-2 border border-blue-100">
                      <i class="fa-solid fa-user text-blue-400"></i> {@assigned_person.person_name}
                    </span>
                  </div>
                <% else %>
                  <div>
                    <h3 class="text-xs font-bold text-gray-400 uppercase tracking-wider mb-2">
                      Asignado a
                    </h3>
                    
                    <span class="bg-gray-100 px-3 py-1.5 rounded-lg text-sm font-semibold text-gray-500 flex items-center gap-2 border border-gray-200">
                      <i class="fa-solid fa-user-slash text-gray-400"></i> Sin asignar
                    </span>
                  </div>
                <% end %>
                
                <div>
                  <h3 class="text-xs font-bold text-gray-400 uppercase tracking-wider mb-2">
                    Fechas
                  </h3>
                  
                  <div class="flex items-center gap-4 text-xs text-gray-500">
                    <span class="flex items-center gap-1.5">
                      <i class="fa-solid fa-calendar-plus text-gray-400"></i> {Calendar.strftime(
                        @task.created_at,
                        "%d/%m/%Y"
                      )}
                    </span>
                    <span class="flex items-center gap-1.5">
                      <i class="fa-solid fa-clock text-gray-400"></i> {Calendar.strftime(
                        @task.updated_at,
                        "%d/%m/%Y"
                      )}
                    </span>
                  </div>
                </div>
              </div>
            </div>
          <% end %>
          
          <%= if @active_tab == "history" do %>
            <div class="space-y-4">
              <%= if Enum.empty?(@task_events) do %>
                <div class="bg-gray-50 rounded-xl p-8 border border-gray-200 text-center">
                  <i class="fa-solid fa-timeline text-4xl text-gray-300 mb-3"></i>
                  <h3 class="text-sm font-bold text-gray-600">Historial de Cambios</h3>
                  
                  <p class="text-xs text-gray-400 mt-1">
                    No hay eventos registrados para esta tarea aún.
                  </p>
                </div>
              <% else %>
                <div class="relative border-l border-gray-200 ml-4 space-y-6 pb-4">
                  <%= for event <- @task_events do %>
                    <div class="relative pl-6">
                      <div class="absolute -left-1.5 mt-1.5 w-3 h-3 bg-aurora_orange rounded-full border-2 border-white">
                      </div>
                      
                      <div class="bg-white border border-gray-100 rounded-lg p-3 shadow-sm">
                        <div class="flex justify-between items-start mb-2">
                          <h4 class="text-xs font-bold text-gray-800">
                            {event.event_type |> String.split(".") |> List.last()}
                          </h4>
                          
                          <span class="text-[10px] text-gray-400">
                            {Calendar.strftime(event.created_at, "%d/%m/%Y %H:%M:%S")}
                          </span>
                        </div>
                        
                        <div class="text-[10px] text-gray-500 font-mono overflow-hidden">
                          <%= for {k, v} <- Map.drop(Map.from_struct(event.data), [:ou_id, :project_id, :task_id]) do %>
                            <%= if not is_nil(v) do %>
                              <div class="flex gap-2">
                                <span class="text-gray-400 font-bold">{k}:</span>
                                <span class="truncate">{inspect(v)}</span>
                              </div>
                            <% end %>
                          <% end %>
                        </div>
                      </div>
                    </div>
                  <% end %>
                </div>
              <% end %>
            </div>
          <% end %>
          
          <%= if @active_tab == "evaluation" do %>
            <%= if Map.get(@task, :evaluation_score) do %>
              <!-- Mostrar Evaluación -->
              <div class="bg-yellow-50/50 rounded-2xl border border-yellow-100 p-6 shadow-sm">
                <div class="flex items-center justify-between mb-4">
                  <h3 class="text-lg font-bold text-gray-800 flex items-center gap-2">
                    <i class="fa-solid fa-award text-yellow-500"></i> Evaluación de la Tarea
                  </h3>
                  
                  <div class="flex flex-col items-end">
                    <span class="text-xs font-bold text-gray-400 uppercase tracking-wider">
                      Nota Final
                    </span>
                    <span class="text-3xl font-black text-yellow-600">
                      {@task.evaluation_score} <span class="text-lg text-yellow-400">/ 100</span>
                    </span>
                  </div>
                </div>
                
                <div class="bg-white p-4 rounded-xl border border-yellow-100/60">
                  <h4 class="text-xs font-bold text-gray-400 uppercase tracking-wider mb-2">
                    Reseña
                  </h4>
                  
                  <p class="text-sm text-gray-700 italic">"{@task.evaluation_review}"</p>
                </div>
              </div>
            <% else %>
              <!-- Solicitar Evaluación -->
              <div class="bg-gray-50 rounded-xl p-8 border border-gray-200 text-center flex flex-col items-center">
                <i class="fa-solid fa-ranking-star text-4xl text-gray-300 mb-3"></i>
                <h3 class="text-sm font-bold text-gray-600">Evaluación Pendiente</h3>
                
                <%= if @task.status == :completed do %>
                  <p class="text-xs text-gray-500 mt-1 mb-4 max-w-md">
                    La tarea ha sido completada pero aún no tiene una evaluación de desempeño registrada.
                  </p>
                  
                  <button
                    phx-click="open_proposal_create_modal"
                    phx-value-proposal_ou_origin={@app_context.current_ou_id}
                    phx-value-proposal_ou_end={@app_context.current_ou_id}
                    phx-value-proposal_title={"Evaluar Tarea: #{@task.name}"}
                    phx-value-proposal_description={"Se propone asignar una nota de evaluación a la tarea #{@task.task_id}."}
                    phx-value-proposal_power_id="org.task.evaluate"
                    phx-value-power-project_id={@task.project_id}
                    phx-value-power-task_id={@task.task_id}
                    class="px-4 py-2 bg-yellow-500 text-white hover:bg-yellow-600 rounded-lg font-bold flex gap-2 items-center transition-colors shadow-sm"
                  >
                    <i class="fa-solid fa-star"></i> Evaluar Tarea
                  </button>
                <% else %>
                  <p class="text-xs text-gray-400 mt-1">
                    La tarea debe estar en estado <b>Completada</b> para poder ser evaluada.
                  </p>
                <% end %>
              </div>
            <% end %>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end
end
