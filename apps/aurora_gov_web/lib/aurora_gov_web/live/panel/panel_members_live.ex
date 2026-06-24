defmodule AuroraGov.Web.Live.Panel.Members do
require Logger
  use AuroraGov.Web, :live_component
  alias AuroraGov.Context.MembershipContext

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:filter, "all")
      |> assign(:search_query, "")
      |> assign(current_page: 1, total_pages: 0, total_count: 0)
      |> assign(:sort_by, :created_at)
      |> assign(:sort_order, :desc)
      |> stream_configure(:member_list, dom_id: &"member-#{&1.person_id}")
      |> stream(:member_list, [])

    {:ok, socket}
  end

  @impl true
  def update(%{new_membership: member}, socket) do
    current_ou = socket.assigns.app_context.current_ou_id

    socket =
      if member.ou_id == current_ou do
        socket
        |> stream_insert(:member_list, member, at: 0)
      else
        socket
      end

    {:ok, socket}
  end

  @impl true
  def update(%{updated_membership: member}, socket) do
    current_ou = socket.assigns.app_context.current_ou_id

    socket =
      if member.ou_id == current_ou do
        socket
        |> stream_insert(:member_list, member, at: 0)
      else
        socket
      end

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(:app_context, assigns.app_context)
      |> load_members()

    {:ok, socket}
  end

  defp load_members(socket) do
    ou_id = socket.assigns.app_context.current_ou_id

    filters = []

    filters =
      case socket.assigns[:filter] do
        "active" -> [%{"field" => "membership_status", "op" => "==", "value" => "active"} | filters]
        "inactive" -> [%{"field" => "membership_status", "op" => "!=", "value" => "active"} | filters]
        _ -> filters
      end

    filters =
      case socket.assigns[:search_query] do
        query when query in [nil, ""] -> filters
        query -> [%{"field" => "person_name", "op" => "like_and", "value" => query} | filters]
      end

    params = %{
      "page" => socket.assigns.current_page,
      "order_by" => [socket.assigns.sort_by],
      "order_directions" => [socket.assigns.sort_order],
      "filters" => filters
    }

    socket
    |> assign(:loading, true)
    |> start_async(:load_data, fn ->
      :timer.sleep(300)

      MembershipContext.list_memberships_by_ou(ou_id, params)
    end)
  end

  @impl true
  def handle_async(:load_data, {:ok, {:ok, {members, meta}}}, socket) do


    socket =
      socket
      |> assign(:loading, false)
      |> assign(:current_page, meta.current_page)
      |> assign(:total_pages, meta.total_pages)
      |> assign(:total_count, meta.total_count)
      |> stream(:member_list, members, reset: true)

    {:noreply, socket}
  end

  def handle_async(:load_data, reason, socket) do
    Logger.warning("Error al cargar miembros #{reason}")

    socket =
      socket
      |> assign(:loading, false)
      |> put_flash(:error, "No se pudieron cargar los miembros.")

    {:noreply, socket}
  end

  @impl true
  def handle_event("paginate", %{"page" => page}, socket) do
    {:noreply,
     socket
     |> assign(:current_page, String.to_integer(page))
     |> load_members()}
  end

  @impl true
  def handle_event("update_filter", %{"filter" => filter}, socket) do
    {:noreply,
     socket
     |> assign(:filter, filter)
     |> assign(:current_page, 1)
     |> load_members()}
  end

  @impl true
  def handle_event("search", %{"search" => search}, socket) do
    {:noreply,
     socket
     |> assign(:search_query, search)
     |> assign(:current_page, 1)
     |> load_members()}
  end

  @impl true
  def handle_event("sort", %{"field" => field}, socket) do
    field_atom = String.to_existing_atom(field)

    new_order =
      if socket.assigns.sort_by == field_atom and socket.assigns.sort_order == :asc,
        do: :desc,
        else: :asc

    {:noreply,
     socket
     |> assign(:sort_by, field_atom)
     |> assign(:sort_order, new_order)
     |> load_members()}
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
            <.search_field name="search" value={@search_query} placeholder="Búsqueda rápida" />
          </form>

          <button
            phx-click="open_proposal_create_modal"
            phx-value-proposal_ou_origin={@app_context.current_ou_id}
            phx-value-proposal_ou_end={@app_context.current_ou_id}
            phx-value-proposal_power_id="org.membership.start"
            phx-value-power-person_id="999@test.com"
            phx-value-proposal_title="Titulo propuesta"
            phx-value-proposal_description="Descripcion de propuesta en detalle"
            class="justify-center items-center text-lg primary"
          >
            <i class="fa-solid fa-hand text-xl"></i> Nuevo miembro
          </button>
        </div>
      </div>

      <div class="w-full">
        <.table
          id="membership-table"
          rows={@streams.member_list}
          page={@current_page}
          loading={@loading}
          total_pages={@total_pages}
          total_count={@total_count}
          target={@myself}
          on_paginate="paginate"
          on_sort="sort"
          on_row_click={
            fn membership ->
              params = [context: @app_context.current_ou_id]
              JS.patch(~p"/app/members/#{membership.person_id}?#{params}")
            end
          }
        >
          <:top_content></:top_content>

          <:empty_state>
            <div class="flex flex-col items-center justify-center py-4">
              <i class="fa-solid fa-users-between-lines text-4xl text-gray-300 mb-3"></i>
              <h3 class="text-lg font-medium text-gray-900">No se encontraron miembros</h3>
            </div>
          </:empty_state>

          <:col :let={membership} label="Id" field={:person_id}>{membership.person.person_id}</:col>

          <:col :let={membership} label="Nombre" field={:person_name}>
            {membership.person.person_name}
          </:col>

          <:col :let={membership} align="center" label="Miembro desde" field={:created_at}>
            {Timex.lformat!(membership.created_at, "{relative}", "es", :relative)}
          </:col>

          <:col :let={membership} label="Rango" align="center" field={:membership_rank}>
            {membership.membership_rank}
          </:col>

          <:col :let={membership} label="Estado" align="center" field={:membership_status}>
            {membership.membership_status}
          </:col>
        </.table>
      </div>
    </div>
    """
  end
end
