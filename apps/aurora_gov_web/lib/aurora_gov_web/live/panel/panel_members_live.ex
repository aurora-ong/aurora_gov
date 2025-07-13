defmodule MembersPanelComponent do
  use AuroraGovWeb, :live_component

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:filter, "all")
      |> stream_configure(:member_list, dom_id: & &1.person_id)
      |> stream(:member_list, [])

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(:context, assigns.context)
      |> assign(loading: true)
      |> start_async(:load_data, fn ->
        :timer.sleep(1000)
        AuroraGov.Context.MembershipContext.get_all_membership_by_uo(assigns.context)
      end)

    {:ok, socket}
  end

  @impl true
  def handle_async(:load_data, {:ok, member_list}, socket) do
    socket =
      socket
      |> assign(:loading, false)
      |> stream(:member_list, member_list, reset: true)

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <section class="card w-4/6 flex flex-col h-fit justify-center items-center">
      <button
        phx-click="open_gov_modal"
        phx-value-proposal_title="Titulo propuesta"
        phx-value-proposal_description="Descripcion de propuesta en detalle"
        phx-value-proposal_ou_origin="raiz"
        phx-value-proposal_ou_end="raiz.sub"
        phx-value-proposal_power="org.membership.start"
        phx-value-person_id="aperson"
        class="justify-center items-center text-lg primary"
      >
        <i class="fa-solid fa-hand text-xl"></i> Nuevo miembro
      </button>

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
        <%= if @loading do %>
            <.loading_spinner></.loading_spinner>

        <% else %>
          <%!-- <%= if Stream.|.empty?(@streams.member_list) do %>
            <div class="text-center py-10 text-gray-500">
              No hay miembros registrados aún.
            </div>
          <% else %>
            <!-- tu tabla aquí -->
          <% end %> --%>
          <.table id="webs" rows={@streams.member_list}>
            <:col :let={{_id, membership}} label="Person Id">
              {membership.person_id}
            </:col>

            <:col :let={{_id, membership}} label="Person Name">
              {membership.person.person_name}
            </:col>

            <:col :let={{_id, membership}} label="Membership Status">
              <%= case (membership.membership_status) do %>
                <% "junior" -> %>
                  <span class="font-semibold">{membership.membership_status}</span>
                <% "regular" -> %>
                  <span class="font-semibold">{membership.membership_status}</span>
                <% "senior" -> %>
                  <span class="text-red-500 font-semibold">{membership.membership_status}</span>
              <% end %>
            </:col>

            <:col :let={{_id, membership}} label="Miembro desde">
              {membership.created_at}
            </:col>
          </.table>
        <% end %>
      </div>
    </section>
    """
  end

  @impl true
  def handle_event("update_filter", %{"filter" => filter}, socket) do
    IO.inspect(filter, label: "QQ")

    {:noreply, assign(socket, filter: filter)}
  end
end
