defmodule AuroraGov.Web.Components.SmartInputs.UserSelector do
  use AuroraGov.Web, :live_component
  use Phoenix.Component
  alias AuroraGov.Context.MembershipContext
  alias AuroraGov.Projector.Repo
  alias AuroraGov.Projector.Model.Person

  @impl true
  def update(assigns, socket) do
    ou_id =
      assigns[:ou_id] ||
      (assigns[:app_context] && assigns.app_context.current_ou_id) ||
      "barrio_vivo"

    selected_person =
      if assigns.field.value not in [nil, ""] do
        Repo.get(Person, assigns.field.value)
      end

    socket =
      socket
      |> assign(assigns)
      |> assign(:ou_id, ou_id)
      |> assign_new(:query, fn -> "" end)
      |> assign_new(:suggestions, fn -> [] end)
      |> assign(:selected_person, selected_person)
      |> assign(:errors, Enum.map(assigns.field.errors, &translate_error(&1)))

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id={@id} class="relative">
      <label for={@id} class="block text-sm text-gray-700 mb-1 font-semibold">
        {@label || "Usuario"}
      </label>

      <%= if @selected_person do %>
        <div class="flex flex-row border py-2 px-4 rounded-lg items-center bg-gray-100 shadow-sm gap-2">
          <div class="w-6 h-6 rounded-full overflow-hidden bg-white border border-gray-200 shrink-0">
            <img
              src={"https://api.dicebear.com/7.x/notionists/svg?seed=#{@selected_person.person_id}&backgroundColor=e2e8f0"}
              alt="Avatar"
              class="w-full h-full object-cover"
            />
          </div>
          <div class="flex flex-col grow">
            <span class="font-bold text-gray-800">{@selected_person.person_name}</span>
            <span class="text-xs text-gray-500">{@selected_person.person_id}</span>
          </div>

          <button phx-click="clear" type="button" class="text-gray-400 hover:text-gray-600" phx-target={@myself}>
            <i class="fa-solid fa-close text-lg"></i>
          </button>
        </div>
        <input type="hidden" name={@field.name} value={@selected_person.person_id} />
      <% end %>

      <input
        :if={@selected_person == nil}
        type="text"
        id={"input-#{@id}"}
        name={"#{@field.name}_search"}
        value={@query}
        placeholder="Buscar miembro por nombre o ID..."
        phx-target={@myself}
        phx-debounce="300"
        phx-keyup="search"
        phx-change="noop"
        autocomplete="off"
        class={[
          "mt-2 block w-full rounded-lg text-zinc-900 focus:ring-0 sm:text-sm sm:leading-6",
          @errors == [] && "border-zinc-300 focus:border-zinc-400",
          @errors != [] && "border-rose-400 focus:border-rose-400"
        ]}
      />

      <.error :for={msg <- @errors}>{msg}</.error>

      <%= if @suggestions != [] do %>
        <ul class="absolute z-10 bg-white shadow-lg border mt-1 max-h-60 overflow-y-auto w-full rounded-md">
          <%= for person <- @suggestions do %>
            <li
              phx-click="select"
              phx-value-person_id={person.person_id}
              phx-target={@myself}
              class="px-4 py-2 hover:bg-blue-100 cursor-pointer flex justify-between items-center text-sm"
            >
              <div>
                <div class="font-semibold">{person.person_name}</div>
                <div class="text-xs text-gray-500">{person.person_id}</div>
              </div>
            </li>
          <% end %>
        </ul>
      <% end %>
    </div>
    """
  end

  @impl true
  def handle_event("search", %{"value" => query}, socket) do
    suggestions =
      if query in [nil, ""] do
        []
      else
        ou_id = socket.assigns.ou_id

        memberships =
          case MembershipContext.list_memberships_by_ou(ou_id, %{"limit" => 100}) do
            {:ok, {list, _meta}} -> list
            _ -> []
          end

        memberships
        |> Enum.map(& &1.person)
        |> Enum.filter(& &1)
        |> Enum.filter(fn p ->
          String.contains?(String.downcase(p.person_name), String.downcase(query)) or
            String.contains?(String.downcase(p.person_id), String.downcase(query))
        end)
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
  def handle_event("noop", _params, socket), do: {:noreply, socket}

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
     |> assign(selected_person: nil, suggestions: [], query: "")}
  end
end
