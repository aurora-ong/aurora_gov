defmodule AuroraGov.Web.Components.SmartInputs.TaskSelector do
  use AuroraGov.Web, :live_component
  use Phoenix.Component
  alias AuroraGov.Projector.Repo
  alias AuroraGov.Projector.Model.Task
  import Ecto.Query

  @impl true
  def update(assigns, socket) do
    project_id = assigns[:project_id] || nil

    selected_task =
      if assigns.field.value not in [nil, ""] do
        Repo.get(Task, assigns.field.value)
      end

    socket =
      socket
      |> assign(assigns)
      |> assign(:project_id, project_id)
      |> assign_new(:query, fn -> "" end)
      |> assign_new(:suggestions, fn -> [] end)
      |> assign(:selected_task, selected_task)
      |> assign(:errors, Enum.map(assigns.field.errors, &translate_error(&1)))

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="relative w-full">
      <label class="block text-sm font-semibold text-gray-700 mb-1">{@label}</label>

      <%= if @selected_task do %>
        <!-- Tarjeta de Tarea Seleccionada -->
        <div class="flex items-center justify-between p-3.5 bg-emerald-50/40 border border-emerald-100 rounded-xl">
          <div class="flex items-center gap-3">
            <div class="w-9 h-9 rounded-lg bg-emerald-100 flex items-center justify-center text-emerald-600">
              <i class="fa-solid fa-list-check text-base"></i>
            </div>
            <div>
              <div class="text-xs font-bold text-gray-800">{@selected_task.name}</div>
              <div class="text-[10px] text-gray-400">
                Objetivo: {@selected_task.goal} | Estado: {@selected_task.status}
              </div>
            </div>
          </div>
          <button
            type="button"
            phx-click="clear"
            phx-target={@myself}
            class="p-1.5 hover:bg-emerald-100/50 rounded-lg text-gray-400 hover:text-gray-600 transition"
          >
            <i class="fa-solid fa-xmark text-sm"></i>
          </button>
        </div>
        <input type="hidden" name={@field.name} value={@selected_task.task_id} />
      <% else %>
        <%= if is_nil(@project_id) or @project_id == "" do %>
          <!-- Advertencia de dependencia de Proyecto -->
          <div class="flex items-center gap-2 p-3 bg-amber-50/60 border border-amber-100 rounded-xl text-amber-700 text-xs">
            <i class="fa-solid fa-circle-info text-sm"></i>
            <span>Por favor, selecciona un proyecto primero.</span>
          </div>
          <input type="hidden" name={@field.name} value="" />
        <% else %>
          <!-- Input de Búsqueda -->
          <div class="relative">
            <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none text-gray-400">
              <i class="fa-solid fa-magnifying-glass text-sm"></i>
            </div>
            <input
              type="text"
              phx-keyup="search"
              phx-target={@myself}
              value={@query}
              placeholder="Escribe el nombre de la tarea..."
              class="block w-full pl-9 pr-3 py-2.5 bg-gray-50/50 border border-gray-200 rounded-xl focus:bg-white focus:ring-1 focus:ring-aurora_orange focus:border-aurora_orange text-sm placeholder-gray-400"
              autocomplete="off"
            />
            <input type="hidden" name={@field.name} value="" />
          </div>

          <!-- Sugerencias -->
          <%= if not Enum.empty?(@suggestions) do %>
            <div class="absolute z-20 w-full mt-1.5 bg-white border border-gray-150 rounded-xl shadow-xl max-h-48 overflow-y-auto py-1.5">
              <%= for task <- @suggestions do %>
                <button
                  type="button"
                  phx-click="select"
                  phx-value-task_id={task.task_id}
                  phx-target={@myself}
                  class="w-full px-4 py-2 hover:bg-gray-50 flex items-center justify-between text-left transition-colors"
                >
                  <div>
                    <div class="text-xs font-bold text-gray-800">{task.name}</div>
                    <div class="text-[10px] text-gray-400">ID: {task.task_id} | Objetivo: {task.goal}</div>
                  </div>
                  <span class="text-[9px] px-1.5 py-0.5 bg-indigo-50 text-indigo-700 rounded font-semibold uppercase tracking-wider">
                    {task.status}
                  </span>
                </button>
              <% end %>
            </div>
          <% end %>
        <% end %>
      <% end %>

      <!-- Mensajes de Error -->
      <%= for err <- @errors do %>
        <span class="text-xs text-red-500 mt-1 block">
          <i class="fa-solid fa-circle-exclamation mr-1"></i>{err}
        </span>
      <% end %>
    </div>
    """
  end

  @impl true
  def handle_event("search", %{"value" => query}, socket) do
    suggestions =
      if String.trim(query) == "" do
        []
      else
        project_id = socket.assigns.project_id
        db_tasks = Repo.all(
          from(t in Task,
            where: t.project_id == ^project_id and t.status not in [:completed, :cancelled],
            order_by: [asc: t.name]
          )
        )

        db_tasks
        |> Enum.filter(fn t ->
          String.contains?(String.downcase(t.name), String.downcase(query)) or
            String.contains?(String.downcase(t.task_id), String.downcase(query))
        end)
      end

    {:noreply, assign(socket, query: query, suggestions: suggestions, selected_task: nil)}
  end

  @impl true
  def handle_event("select", %{"task_id" => task_id}, socket) do
    selected = Repo.get(Task, task_id)
    parent_module = socket.assigns[:parent_module] || AuroraGov.Web.Live.Panel.ProposalCreate
    parent_id = socket.assigns[:parent_id] || "modal-proposal_create"

    Phoenix.LiveView.send_update(
      parent_module,
      id: parent_id,
      info: {:task_selected, socket.assigns.field.field, selected.task_id}
    )

    {:noreply,
     socket
     |> assign(selected_task: selected, suggestions: [], query: "")}
  end

  @impl true
  def handle_event("clear", _params, socket) do
    parent_module = socket.assigns[:parent_module] || AuroraGov.Web.Live.Panel.ProposalCreate
    parent_id = socket.assigns[:parent_id] || "modal-proposal_create"

    Phoenix.LiveView.send_update(
      parent_module,
      id: parent_id,
      info: {:task_selected, socket.assigns.field.field, nil}
    )

    {:noreply,
     socket
     |> assign(selected_task: nil, query: "")}
  end
end
