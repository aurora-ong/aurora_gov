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
        {@label || "Unidad"}
      </label>
      <%= if @selected_ou do %>
        <div class="flex flex-row border py-2 px-4 rounded-lg items-center bg-gray-100 shadow-md">
          <div class="flex items-center justify-center w-10 h-10 rounded-full overflow-hidden shrink-0 bg-gray-200 border border-gray-300 mr-3">
             <%= if @selected_ou[:ou_avatar_url] do %>
               <img src={@selected_ou.ou_avatar_url} class="w-full h-full object-cover" />
             <% else %>
               <i class="fa-solid fa-sitemap text-aurora_orange text-lg rotate-180"></i>
             <% end %>
          </div>

          <div class="flex flex-col grow">
             <span class="font-bold">{@selected_ou.ou_name}</span>
             <div class="flex flex-row gap-2 items-center mt-1">
               <.ou_id_badge id={@selected_ou.ou_id} size="sm" />
               <%= if Map.get(@selected_ou, :membership_rank) do %>
                 <.membership_rank_badge rank={@selected_ou.membership_rank} />
               <% end %>
             </div>
          </div>

          <button phx-click="clear" type="button" class="" phx-target={@myself}>
            <i class="fa-solid fa-close text-2xl"></i>
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
              class="px-4 py-3 hover:bg-blue-50 cursor-pointer flex justify-between items-center"
            >
              <div class="flex flex-row items-center gap-3">
                <div class="flex items-center justify-center w-8 h-8 rounded-full overflow-hidden shrink-0 bg-gray-200 border border-gray-300">
                   <%= if Map.get(ou, :ou_avatar_url) do %>
                     <img src={ou.ou_avatar_url} class="w-full h-full object-cover" />
                   <% else %>
                     <i class="fa-solid fa-sitemap text-aurora_orange text-sm rotate-180"></i>
                   <% end %>
                </div>
                
                <div class="flex flex-col">
                  <div class="font-semibold text-sm">{ou.ou_name}</div>
                  <div class="flex flex-row gap-2 mt-1 items-center">
                    <.ou_id_badge id={ou.ou_id} size="sm" />
                    <%= if Map.get(ou, :membership_rank) do %>
                      <.membership_rank_badge rank={ou.membership_rank} />
                    <% end %>
                  </div>
                </div>
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
