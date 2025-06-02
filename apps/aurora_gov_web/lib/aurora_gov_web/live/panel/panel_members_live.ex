defmodule MembersPanelComponent do
  # In Phoenix apps, the line is typically: use MyAppWeb, :live_component
  use Phoenix.LiveComponent

  @impl true
  def mount(socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(AuroraGov.PubSub, "projector_update")
    end

    socket =
      socket
      |> assign(:filter, "all")

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(:context, assigns.context)
      |> assign(
        :members,
        AuroraGov.Projector.Membership.get_all_membership_by_uo(assigns.context)
      )

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <section class="card w-4/6 flex flex-col h-fit justify-center items-center">
      <div class="flex w-full h-12 flex-row">
        <div class="flex w-fit grow">
          <ul class="flex flex-row gap-3 items-center tabs">
            <li class={if @filter == "all", do: "active", else: ""}>
              <a phx-click="update_filter" phx-value-filter="all" phx-target={@myself}>Todos</a>
            </li>

            <li class={if @filter == "new", do: "active", else: ""}>
              <a phx-click="update_filter" phx-value-filter="new" phx-target={@myself}>Nuevos</a>
            </li>

            <li class={if @filter == "active", do: "active", else: ""}>
              <a phx-click="update_filter" phx-value-filter="active" phx-target={@myself}>Activos</a>
            </li>

            <li class={if @filter == "inactive", do: "active", else: ""}>
              <a phx-click="update_filter" phx-value-filter="inactive" phx-target={@myself}>
                Inactivos
              </a>
            </li>
          </ul>
        </div>
      </div>
       <hr class="my-5" />
      <div class="relative overflow-x-auto w-full">
        <table class="w-full text-md text-left text-gray-500">
          <thead class="text-gray-700 uppercase bg-gray-100 text-center">
            <tr>
              <%!-- <th scope="col" class="px-6 py-3">
                Id
              </th> --%>

              <th scope="col" class="px-6 py-3">
                Nombre miembro
              </th>

              <th scope="col" class="px-6 py-3">
                Status miembro
              </th>

              <th scope="col" class="px-6 py-3">
                Miembro desde
              </th>
            </tr>
          </thead>

          <tbody>
            <%= for m <- @members do %>
              <tr class="bg-gray-50 hover:bg-gray-100 border-b">
                <%!-- <th
                  scope="row"
                  class="px-6 py-4 font-medium text-gray-900 whitespace-nowrap text-center"
                >
                  {m.person.person_id}
                </th> --%>

                <th
                  scope="row"
                  class="px-6 py-4 font-medium text-gray-900 whitespace-nowrap text-center"
                >
                  {m.person.person_name}
                </th>

                <td class="px-6 py-4 text-center">
                  {m.membership_status}
                </td>

                <td class="px-6 py-4 text-center">
                  {m.created_at}
                </td>
              </tr>
            <% end %>
          </tbody>
        </table>
      </div>
    </section>
    """
  end

  @impl true
  def handle_event("update_filter", %{"filter" => filter}, socket) do
    IO.inspect(filter, label: "QQ")

    {:noreply, assign(socket, filter: filter)}
  end

  def handle_info(msg, socket) do
    IO.inspect(msg, label: "Actualizando PUBSUB Panel Members")
    {:noreply, socket}
  end
end
