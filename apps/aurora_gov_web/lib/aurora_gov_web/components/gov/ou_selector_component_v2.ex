defmodule AuroraGov.Web.Components.SmartInputs.OUSelector do
  use AuroraGov.Web, :live_component
  use Phoenix.Component
  alias AuroraGov.Context.OUContext

  @impl true
  def update(assigns, socket) do
    person = assigns[:app_context] && assigns.app_context.current_person

    ou_tree =
      if person && person.person_id do
        case OUContext.get_ou_tree_with_membership(person.person_id) do
          {:error, _} -> []
          list -> list
        end
      else
        []
      end

    selected_ou =
      if assigns.field.value not in [nil, ""] do
        Enum.find(ou_tree, fn ou -> ou.ou_id == assigns.field.value end) ||
          OUContext.get_ou(assigns.field.value)
      end

    socket =
      socket
      |> assign(assigns)
      |> assign(:ou_tree, ou_tree)
      |> assign_new(:query, fn -> "" end)
      |> assign_new(:suggestions, fn -> [] end)
      |> assign(:selected_ou, selected_ou)
      |> assign(:errors, Enum.map(assigns.field.errors, &translate_error(&1)))

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id={@id} class="relative">
      <label for={@id} class="block text-sm text-gray-700 mb-1 font-semibold">
        {@label || "Unidad"}
      </label>

      <%= if @selected_ou do %>
        <div class="flex flex-row border py-2 px-4 rounded-lg items-center bg-gray-100 shadow-sm gap-2">
          <div class="flex flex-col grow">
            <span class="text-white w-fit bg-black px-2 py-0.5 font-semibold text-xs rounded mb-0.5">
              {@selected_ou.ou_id}
            </span>
            <span class="font-bold text-gray-800">{@selected_ou.ou_name}</span>
          </div>

          <button phx-click="clear" type="button" class="text-gray-400 hover:text-gray-600" phx-target={@myself}>
            <i class="fa-solid fa-close text-lg"></i>
          </button>
        </div>
        <input type="hidden" name={@field.name} value={@selected_ou.ou_id} />
      <% end %>

      <input
        :if={@selected_ou == nil}
        type="text"
        id={"input-#{@id}"}
        name={"#{@field.name}_search"}
        value={@query}
        placeholder="Buscar unidad barrial por nombre o ID..."
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
          <%= for ou <- @suggestions do %>
            <li
              phx-click="select"
              phx-value-ou_id={ou.ou_id}
              phx-target={@myself}
              class="px-4 py-2 hover:bg-blue-100 cursor-pointer flex justify-between items-center text-sm"
            >
              <div>
                <div class="font-semibold">{ou.ou_name}</div>
                <div class="text-xs text-gray-500">ID: {ou.ou_id}</div>
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
        ou_tree = socket.assigns.ou_tree || []

        Enum.filter(ou_tree, fn ou ->
          String.contains?(String.downcase(ou.ou_name), String.downcase(query)) or
            String.contains?(String.downcase(ou.ou_id), String.downcase(query))
        end)
      end

    {:noreply, assign(socket, query: query, suggestions: suggestions, selected_ou: nil)}
  end

  @impl true
  def handle_event("select", %{"ou_id" => ou_id}, socket) do
    selected =
      Enum.find(socket.assigns.ou_tree, fn ou -> ou.ou_id == ou_id end) ||
        OUContext.get_ou(ou_id)

    parent_module = socket.assigns[:parent_module] || AuroraGov.Web.Live.Panel.ProposalCreate
    parent_id = socket.assigns[:parent_id] || "modal-proposal_create"

    Phoenix.LiveView.send_update(
      parent_module,
      id: parent_id,
      info: {:ou_selected, socket.assigns.field.field, selected.ou_id}
    )

    {:noreply,
     socket
     |> assign(selected_ou: selected, suggestions: [], query: "")}
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
      info: {:ou_selected, socket.assigns.field.field, nil}
    )

    {:noreply,
     socket
     |> assign(selected_ou: nil, suggestions: [], query: "")}
  end
end
