defmodule AuroraGov.Web.Components.SmartInputs.GlobalUserSelector do
  use AuroraGov.Web, :live_component
  use Phoenix.Component
  alias AuroraGov.Projector.Repo
  alias AuroraGov.Projector.Model.Person
  import Ecto.Query

  @impl true
  def update(assigns, socket) do
    selected_person =
      if assigns.field.value not in [nil, ""] do
        Repo.get(Person, assigns.field.value)
      end

    socket =
      socket
      |> assign(assigns)
      |> assign_new(:query, fn -> "" end)
      |> assign_new(:suggestions, fn -> [] end)
      |> assign(:selected_person, selected_person)
      |> assign(:errors, Enum.map(assigns.field.errors, &translate_error(&1)))

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="relative w-full">
      <label class="block text-sm font-semibold text-gray-700 mb-1">{@label}</label>

      <%= if @selected_person do %>
        <!-- Tarjeta de Persona Seleccionada -->
        <div class="flex items-center justify-between p-3.5 bg-indigo-50/40 border border-indigo-100 rounded-xl">
          <div class="flex items-center gap-3">
            <div class="w-9 h-9 rounded-full overflow-hidden bg-white border border-gray-200">
              <img
                src={"https://api.dicebear.com/7.x/notionists/svg?seed=#{@selected_person.person_id}&backgroundColor=e2e8f0"}
                alt="Avatar"
                class="w-full h-full object-cover"
              />
            </div>
            <div>
              <div class="text-xs font-bold text-gray-800">{@selected_person.person_name}</div>
              <div class="text-[10px] text-gray-400">ID/Email: {@selected_person.person_id}</div>
            </div>
          </div>
          <button
            type="button"
            phx-click="clear"
            phx-target={@myself}
            class="p-1.5 hover:bg-indigo-100/50 rounded-lg text-gray-400 hover:text-gray-600 transition"
          >
            <i class="fa-solid fa-xmark text-sm"></i>
          </button>
        </div>
        <input type="hidden" name={@field.name} value={@selected_person.person_id} />
      <% else %>
        <!-- Input de Búsqueda -->
        <div class="relative">
          <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none text-gray-400">
            <i class="fa-solid fa-earth-americas text-sm"></i>
          </div>
          <input
            type="text"
            phx-keyup="search"
            phx-target={@myself}
            value={@query}
            placeholder="Buscar por nombre o email global..."
            class="block w-full pl-9 pr-3 py-2.5 bg-gray-50/50 border border-gray-200 rounded-xl focus:bg-white focus:ring-1 focus:ring-aurora_orange focus:border-aurora_orange text-sm placeholder-gray-400"
            autocomplete="off"
          />
          <input type="hidden" name={@field.name} value="" />
        </div>

        <!-- Sugerencias -->
        <%= if not Enum.empty?(@suggestions) do %>
          <div class="absolute z-20 w-full mt-1.5 bg-white border border-gray-150 rounded-xl shadow-xl max-h-48 overflow-y-auto py-1.5">
            <%= for person <- @suggestions do %>
              <button
                type="button"
                phx-click="select"
                phx-value-person_id={person.person_id}
                phx-target={@myself}
                class="w-full px-4 py-2 hover:bg-gray-50 flex items-center gap-3 text-left transition-colors"
              >
                <div class="w-8 h-8 rounded-full overflow-hidden bg-gray-100 border border-gray-200 shrink-0">
                  <img
                    src={"https://api.dicebear.com/7.x/notionists/svg?seed=#{person.person_id}&backgroundColor=e2e8f0"}
                    alt="Avatar"
                    class="w-full h-full object-cover"
                  />
                </div>
                <div>
                  <div class="text-xs font-bold text-gray-800">{person.person_name}</div>
                  <div class="text-[10px] text-gray-400">ID/Email: {person.person_id}</div>
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
        query_pattern = "%#{query}%"
        Repo.all(
          from(p in Person,
            where: ilike(p.person_name, ^query_pattern) or ilike(p.person_id, ^query_pattern),
            limit: 10,
            order_by: [asc: p.person_name]
          )
        )
      end

    {:noreply, assign(socket, query: query, suggestions: suggestions, selected_person: nil)}
  end

  @impl true
  def handle_event("select", %{"person_id" => person_id}, socket) do
    selected = Repo.get(Person, person_id)
    parent_module = socket.assigns[:parent_module] || AuroraGov.Web.Live.Panel.ProposalCreate
    parent_id = socket.assigns[:parent_id] || "modal-proposal_create"

    Phoenix.LiveView.send_update(
      parent_module,
      id: parent_id,
      info: {:user_selected, socket.assigns.field.field, selected.person_id}
    )

    {:noreply,
     socket
     |> assign(selected_person: selected, suggestions: [], query: "")}
  end

  @impl true
  def handle_event("clear", _params, socket) do
    parent_module = socket.assigns[:parent_module] || AuroraGov.Web.Live.Panel.ProposalCreate
    parent_id = socket.assigns[:parent_id] || "modal-proposal_create"

    Phoenix.LiveView.send_update(
      parent_module,
      id: parent_id,
      info: {:user_selected, socket.assigns.field.field, nil}
    )

    {:noreply,
     socket
     |> assign(selected_person: nil, query: "")}
  end
end
