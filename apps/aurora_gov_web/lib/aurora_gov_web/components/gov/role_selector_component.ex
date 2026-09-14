defmodule AuroraGov.Web.Components.SmartInputs.RoleSelector do
  use AuroraGov.Web, :live_component
  use Phoenix.Component
  alias AuroraGov.Projector.Repo
  alias AuroraGov.Projector.Model.OURole
  import Ecto.Query

  @impl true
  def update(assigns, socket) do
    ou_id =
      assigns[:ou_id] ||
      (assigns[:app_context] && assigns.app_context.current_ou_id) ||
      "barrio_vivo"

    selected_role =
      if assigns.field.value not in [nil, ""] do
        Repo.get(OURole, assigns.field.value)
      end

    socket =
      socket
      |> assign(assigns)
      |> assign(:ou_id, ou_id)
      |> assign_new(:query, fn -> "" end)
      |> assign_new(:suggestions, fn -> [] end)
      |> assign(:selected_role, selected_role)
      |> assign(:errors, Enum.map(assigns.field.errors, &translate_error(&1)))

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="relative w-full">
      <label class="block text-sm font-semibold text-gray-700 mb-1">{@label}</label>

      <%= if @selected_role do %>
        <!-- Tarjeta de Rol Seleccionado -->
        <div class="flex items-center justify-between p-3.5 bg-purple-50/40 border border-purple-100 rounded-xl">
          <div class="flex items-center gap-3">
            <div class="w-9 h-9 rounded-lg bg-purple-100 flex items-center justify-center text-purple-600">
              <i class="fa-solid fa-id-card-clip text-base"></i>
            </div>
            <div>
              <div class="text-xs font-bold text-gray-800">{@selected_role.role_name}</div>
              <div class="text-[10px] text-gray-400">ID: {@selected_role.role_id}</div>
            </div>
          </div>
          <button
            type="button"
            phx-click="clear"
            phx-target={@myself}
            class="p-1.5 hover:bg-purple-100/50 rounded-lg text-gray-400 hover:text-gray-600 transition"
          >
            <i class="fa-solid fa-xmark text-sm"></i>
          </button>
        </div>
        <input type="hidden" name={@field.name} value={@selected_role.role_id} />
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
            placeholder="Escribe el nombre del rol..."
            class="block w-full pl-9 pr-3 py-2.5 bg-gray-50/50 border border-gray-200 rounded-xl focus:bg-white focus:ring-1 focus:ring-aurora_orange focus:border-aurora_orange text-sm placeholder-gray-400"
            autocomplete="off"
          />
          <input type="hidden" name={@field.name} value="" />
        </div>

        <!-- Sugerencias -->
        <%= if not Enum.empty?(@suggestions) do %>
          <div class="absolute z-20 w-full mt-1.5 bg-white border border-gray-150 rounded-xl shadow-xl max-h-48 overflow-y-auto py-1.5">
            <%= for role <- @suggestions do %>
              <button
                type="button"
                phx-click="select"
                phx-value-role_id={role.role_id}
                phx-target={@myself}
                class="w-full px-4 py-2 hover:bg-gray-50 flex items-center justify-between text-left transition-colors"
              >
                <div>
                  <div class="text-xs font-bold text-gray-800">{role.role_name}</div>
                  <div class="text-[10px] text-gray-400">ID: {role.role_id}</div>
                </div>
              </button>
            <% end %>
          </div>
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
        ou_id = socket.assigns.ou_id
        db_roles = Repo.all(
          from(r in OURole,
            where: r.ou_id == ^ou_id and r.status == "active",
            order_by: [asc: r.role_name]
          )
        )

        db_roles
        |> Enum.filter(fn r ->
          String.contains?(String.downcase(r.role_name), String.downcase(query)) or
            String.contains?(String.downcase(r.role_id), String.downcase(query))
        end)
      end

    {:noreply, assign(socket, query: query, suggestions: suggestions, selected_role: nil)}
  end

  @impl true
  def handle_event("select", %{"role_id" => role_id}, socket) do
    selected = Repo.get(OURole, role_id)
    parent_module = socket.assigns[:parent_module] || AuroraGov.Web.Live.Panel.ProposalCreate
    parent_id = socket.assigns[:parent_id] || "modal-proposal_create"

    Phoenix.LiveView.send_update(
      parent_module,
      id: parent_id,
      info: {:role_selected, socket.assigns.field.field, selected.role_id}
    )

    {:noreply,
     socket
     |> assign(selected_role: selected, suggestions: [], query: "")}
  end

  @impl true
  def handle_event("clear", _params, socket) do
    parent_module = socket.assigns[:parent_module] || AuroraGov.Web.Live.Panel.ProposalCreate
    parent_id = socket.assigns[:parent_id] || "modal-proposal_create"

    Phoenix.LiveView.send_update(
      parent_module,
      id: parent_id,
      info: {:role_selected, socket.assigns.field.field, nil}
    )

    {:noreply,
     socket
     |> assign(selected_role: nil, query: "")}
  end
end
