defmodule AuroraGov.Web.OUSelectorComponent do
  use AuroraGov.Web, :live_component
  use Phoenix.Component

  @impl true
  def update(assigns, socket) do
    # IO.inspect(assigns, label: "OU COmponent assign")

    # errors = if Phoenix.Component.used_input?(assigns.field), do: assigns.field.errors, else: []

    socket =
      socket
      |> assign(assigns)
      |> assign_new(:query, fn -> "" end)
      |> assign_new(:suggestions, fn -> [] end)
      |> assign_new(:selected_ou, fn ->
        if assigns.field.value != nil do
          Enum.find(assigns.ou_tree, fn ou ->
            ou.ou_id == assigns.field.value
          end)
        end
      end)
      |> assign(:errors, Enum.map(assigns.field.errors, &translate_error(&1)))

    {:ok, socket}
  end

  attr :description, :string, required: false, default: nil
  attr :label, :string, required: false, default: nil
  @impl true
  def render(assigns) do
    ~H"""
    <div id={@id} class="relative">
      <label for={@id} class="block text-sm text-gray-700 mb-1 font-semibold">
        {@label || "Organización"}
      </label>
       <%!-- <.label for={@id}>{@label}</.label> --%>
      <%= if @selected_ou do %>
        <div class="flex flex-row border py-2 px-4 rounded-lg items-center bg-gray-100 shadow-md">
          <div class="flex flex-col grow">
            <span class="text-white w-fit bg-black px-2 py-0.5 font-semibold text-sm rounded">
              {@selected_ou.ou_id}
            </span>
             <span>{@selected_ou.ou_name}</span>
          </div>

          <button phx-click="clear" type="button" class="" phx-target={@myself}>
            <i class="fa-solid fa-close text-2xl"></i>
          </button>
        </div>
         <input type="hidden" name={@field.name} value={@selected_ou.ou_id} />
      <% end %>

      <%!-- <.input
        :if={@selected_ou == nil}
        field={@field}
        type="text"
        label={@label}
        value={@query}
        placeholder="Escribe el nombre o ID de la unidad..."
        phx-target={@myself}
        phx-debounce="300"
        phx-keyup="search"
        autocomplete="off"
      /> --%>
      <input
        :if={@selected_ou == nil}
        type="text"
        id={"input-#{@id}"}
        name={"#{@field.name}_search"}
        value={@query}
        placeholder="Escribe el nombre o ID de la unidad..."
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
      <%= if @description != nil do %>
        <p class="text-xs mt-1">{@description}</p>
      <% end %>

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

    send(self(), {:ou_selected, socket.assigns.field.field, ou_id})

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

  @impl true
  def handle_event("clear", _params, socket) do
    Phoenix.LiveView.send_update(
      socket.assigns.parent_module,
      id: socket.assigns.parent_id,
      info: {:ou_selected, socket.assigns.field.field, nil}
    )

    {:noreply,
     socket
     |> assign(selected_ou: nil, suggestions: [], query: "")}
  end
end
