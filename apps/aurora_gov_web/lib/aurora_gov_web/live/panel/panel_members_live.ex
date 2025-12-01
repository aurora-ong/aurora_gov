defmodule AuroraGovWeb.Live.Panel.Members do
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
      |> assign(:app_context, assigns.app_context)
      |> assign(loading: true)
      |> start_async(:load_data, fn ->
        :timer.sleep(100)
        AuroraGov.Context.MembershipContext.get_all_membership_by_uo(assigns.app_context.current_ou_id)
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
    <div class="w-full h-full p-6">
      <div class="flex w-full h-12 flex-row justify-between mb-5">
        <.filter_button_group
          options={[
            %{label: "Todos", value: "all"},
            %{label: "Activos", value: "active"},
            %{label: "Inactivos", value: "inactive"}
          ]}
          selected={@filter}
          on_select="update_filter"
          phx_target={@myself}
        />
        <div class="flex flex-row gap-3">
          <form phx-change="search" phx-target={@myself} class="flex items-center gap-2">
            <.search_field name="search" value="" placeholder="Búsqueda rápida" />
          </form>

          <%!-- <button
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
          </button> --%>

          <.dropdown
            id="action-dropdown"
            relative="md:relative"
            size="large"
            padding="extra_big"
          >
            <:trigger class="flex justify-center items-center">
              <button class="justify-center items-center text-lg primary outlined">
                <i class="fa-solid fa-hand text-xl"></i>
              </button>
            </:trigger>

            <:content>
              <div class="flex flex-col gap-1">
                <.action_button
                  size="md"
                  phx-click="mi_evento"
                  phx-value-id="123"
                  phx-target={@myself}
                >
                  Nuevo miembro
                </.action_button>

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
              </div>
            </:content>
          </.dropdown>
        </div>
      </div>

      <div class="relative overflow-x-auto w-full">
        <%= if @loading do %>
          <.loading_spinner size="double_large" />
        <% else %>
          <%!-- <%= if Stream.|.empty?(@streams.member_list) do %>
            <div class="text-center py-10 text-gray-500">
              No hay miembros registrados aún.
            </div>
          <% else %>
            <!-- tu tabla aquí -->
          <% end %> --%>
          <.table
            thead_class="bg-gray-50 w-full"
            text_size="medium"
            id="members"
            rows={@streams.member_list}
          >
            <:header class="">Id Persona</:header>

            <:header class="">Nombre</:header>

            <:header class="text-center">Rango</:header>

            <:header class="text-center">Miembro desde</:header>

            <:col :let={{_id, membership}}>
              {membership.person_id}
            </:col>

            <:col :let={{_id, membership}}>
              {membership.person.person_name}
            </:col>

            <:col :let={{_id, membership}} class="text-center">
              <%= case (membership.membership_status) do %>
                <% "junior" -> %>
                  <.badge size="medium" class="font-semibold" rounded="full">
                    {membership.membership_status}
                  </.badge>
                <% "regular" -> %>
                  <.badge size="medium" class="font-semibold" rounded="full">
                    {membership.membership_status}
                  </.badge>
                <% "senior" -> %>
                  <.badge size="medium" class="text-red-500 font-semibold" rounded="full">
                    {membership.membership_status}
                  </.badge>
              <% end %>
            </:col>

            <:col :let={{_id, membership}} class="text-center">
              {Timex.lformat!(membership.created_at, "{relative}", "es", :relative)}
            </:col>

            <:footer class="text-sm w-100 bg-gray-50">Total 4 miembros</:footer>
          </.table>
        <% end %>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("update_filter", %{"filter" => filter}, socket) do
    IO.inspect(filter, label: "update_filter")
    {:noreply, assign(socket, filter: filter)}
  end
end
