defmodule AuroraGovWeb.OUSelectorComponent do
  use AuroraGovWeb, :live_component

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_new(:query, fn -> "" end)
      |> assign_new(:suggestions, fn -> [] end)
      |> assign_new(:selected_ou, fn -> nil end)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id={@id} class="relative">
      <label for={@id} class="block text-sm font-medium text-gray-700 mb-1">
        {@label || "Organización"}
      </label>

      <input
        type="text"
        id={"input-#{@id}"}
        name={"#{@field.name}_search"}
        value={(@selected_ou && @selected_ou.ou_name) || @query}
        placeholder="Escribe el nombre o ID de la unidad..."
        phx-target={@myself}
        phx-debounce="300"
        phx-keyup="search"
        phx-change="noop"
        autocomplete="off"
        class={[
          "w-full border rounded-md px-3 py-2 shadow-sm focus:outline-none focus:ring-2",
          (@selected_ou && "bg-green-50 border-green-500 ring-green-300") || ""
        ]}
      />
      <%= if @selected_ou do %>
        <input type="hidden" name={@field.name} value={@selected_ou.ou_id} />
      <% end %>

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

              <div class="text-xs font-medium">
                <%= if ou.membership_status do %>
                  <span class="text-green-600">✓ Miembro</span>
                <% else %>
                  <span class="text-gray-400 italic">No miembro</span>
                <% end %>
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
    ou_tree = socket.assigns.ou_tree || []
    _only_if_member? = socket.assigns[:only_if_member?] || false

    results =
      Enum.filter(ou_tree, fn ou ->
        match?(
          true,
          String.contains?(String.downcase(ou.ou_name), String.downcase(query)) or
            String.contains?(String.downcase(ou.ou_id), String.downcase(query))
        )
      end)

    # |> Enum.filter(fn ou ->
    #   not only_if_member? or ou.membership_status in [:junior, :formal, :senior]
    # end)

    {:noreply, assign(socket, query: query, suggestions: results, selected_ou: nil)}
  end

  @impl true
  def handle_event("select", %{"ou_id" => ou_id}, socket) do
    selected =
      Enum.find(socket.assigns.ou_tree, fn ou ->
        ou.ou_id == ou_id
      end)

    Phoenix.LiveView.send_update(
      socket.assigns.parent_module,
      id: socket.assigns.parent_id,
      info: {:ou_selected, socket.assigns.field.field, selected.ou_id}
    )

    {:noreply,
     socket
     |> assign(selected_ou: selected, suggestions: [], query: "")}
  end

  @impl true
  def handle_event("noop", _params, socket), do: {:noreply, socket}
end
