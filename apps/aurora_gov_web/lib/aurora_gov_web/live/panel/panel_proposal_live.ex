defmodule AuroraGov.Web.Live.Panel.Proposals do
  use AuroraGov.Web, :live_component

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:search, "")
      |> assign(:filter_type, "internal")
      |> assign(current_page: 1, total_pages: 0, total_count: 0)
      |> assign(:sort_by, :created_at)
      |> assign(:sort_order, :desc)
      |> assign(:loading, true)
      |> stream_configure(:proposal_list, dom_id: & &1.proposal_id)
      |> stream(:proposal_list, [])

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    filter_type = socket.assigns[:filter_type] || "internal"
    filter_search = socket.assigns[:search] || ""
    params = assigns[:params] || %{}

    socket =
      socket
      |> assign(:app_context, assigns.app_context)
      |> assign(:loading, true)
      |> start_async(:load_proposals, fn ->
        fetch_proposals(assigns.app_context, filter_type, filter_search, params)
      end)

    {:ok, socket}
  end

  defp fetch_proposals(context, filter_type, search, params) do
    current_ou_id = context.current_ou_id

    filters =
      case filter_type do
        "out" ->
          [
            %{field: :proposal_ou_start_id, op: :==, value: current_ou_id},
            %{field: :proposal_ou_end_id, op: :!=, value: current_ou_id}
          ]

        "in" ->
          [
            %{field: :proposal_ou_end_id, op: :==, value: current_ou_id},
            %{field: :proposal_ou_start_id, op: :!=, value: current_ou_id}
          ]

        "internal" ->
          [
            %{field: :proposal_ou_end_id, op: :==, value: current_ou_id},
            %{field: :proposal_ou_start_id, op: :==, value: current_ou_id}
          ]

        _ ->
          []
      end

    filters =
      if search != "",
        do: filters ++ [%{field: :proposal_title, op: :ilike, value: "%" <> search <> "%"}],
        else: filters

    params = Map.put(params, :filters, filters)

    case AuroraGov.Context.ProposalContext.list_proposals(params) do
      {proposals, meta} -> {proposals, meta}
    end
  end

  @impl true
  def handle_async(:load_proposals, {:ok, {proposals, meta}}, socket) do
    socket =
      socket
      |> assign(:loading, false)
      |> assign(:current_page, meta.current_page)
      |> assign(:total_pages, meta.total_pages)
      |> assign(:total_count, meta.total_count)
      |> stream(:proposal_list, proposals, reset: true)

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="w-full h-full p-6">
      <.table
        id="proposal-table"
        rows={@streams.proposal_list}
        page={@current_page}
        loading={@loading}
        total_pages={@total_pages}
        total_count={@total_count}
        target={@myself}
        on_paginate="paginate"
        on_sort="sort"
        on_row_click={
          fn proposal ->
            params = [context: @app_context.current_ou_id]
            JS.patch(~p"/app/proposals/#{proposal.proposal_id}?#{params}")
          end
        }
      >
        <:top_content>
          <div class="flex flex-col md:flex-row w-full justify-between items-center mb-4 gap-2">
            <div class="flex gap-2">
              <.filter_button_group
                options={[
                  %{label: "Internas", value: "internal"},
                  %{label: "Entrantes", value: "in"},
                  %{label: "Salientes", value: "out"}
                ]}
                selected={@filter_type}
                on_select="update_filter"
                phx_target={@myself}
              />
            </div>

            <form phx-change="search" phx-target={@myself} class="flex items-center gap-2">
              <.search_field
                search_button
                name="search"
                value={@search}
                placeholder="Búsqueda rápida"
                class="bg-amber-200"
              />
            </form>
          </div>
        </:top_content>

        <:empty_state>
          <div class="flex flex-col items-center justify-center py-4">
            <i class="fa-solid fa-hand text-4xl text-gray-300 mb-3"></i>
            <h3 class="text-lg font-medium text-gray-900">No se encontraron resultados.</h3>
          </div>
        </:empty_state>

        <:col :let={proposal} label="Estado" align="center" class="align-middle">
          <div class="flex justify-center items-center h-full">
            <%= case proposal.proposal_status do %>
              <% :consumed -> %>
                <div class="flex items-center" title="Completada">
                  <i class={"fa fa-check-circle text-3xl " <> if proposal.proposal_execution_result == :success, do: "text-green-600", else: "text-red-600"}>
                  </i>
                </div>
              <% :executing -> %>
                <div class="flex items-center" title="Ejecutando">
                  <i class="fa-regular fa-circle text-blue-500 text-3xl animate-pulse"></i>
                </div>
              <% :active -> %>
                <div class="flex items-center" title="Activa">
                  <i class="fa fa-play-circle text-aurora_orange text-3xl"></i>
                </div>
              <% _ -> %>
            <% end %>
          </div>
        </:col>

        <:col :let={proposal} label="Propuesta">
          <div class="flex flex-col">
            <div class="flex-row flex">
              <%= if proposal.proposal_ou_start_id != proposal.proposal_ou_end_id do %>
                <.ou_id_badge
                  ou_id={proposal.proposal_ou_start_id}
                  ou_name={proposal.proposal_ou_start.ou_name}
                  size="sm"
                />
                <span class="mx-2 text-gray-400 flex items-center">
                  <i class="fa fa-arrow-right"></i>
                </span>
                <.ou_id_badge
                  ou_id={proposal.proposal_ou_end_id}
                  ou_name={proposal.proposal_ou_end.ou_name}
                  size="sm"
                />
              <% else %>
                <.ou_id_badge
                  ou_id={proposal.proposal_ou_end_id}
                  ou_name={proposal.proposal_ou_end.ou_name}
                  size="sm"
                />
              <% end %>
            </div>

            <h3 class="text-lg text-black">{proposal.proposal_title}</h3>
          </div>
        </:col>

        <:col :let={proposal} label="Fecha" align="center">
          <p class="text-md text-gray-600 font-normal">
            {Timex.lformat!(proposal.created_at, "{relative}", "es", :relative)}
          </p>
        </:col>

        <:col :let={proposal} label="Responsable" align="center">
          <.badge
            icon="fa-user fa-solid"
            size="sm"
            class="hover:bg-gray-100 border border-gray-300 rounded-full p-2 cursor-pointer"
            patch={~p"/app/members/#{proposal.proposal_owner.person_id}"}
          >
            {proposal.proposal_owner.person_name}
          </.badge>
        </:col>

        <:col :let={proposal} label="Poder" align="center">
          <.badge
            icon="fa-bolt fa-solid"
            size="sm"
            class="hover:bg-gray-100 border border-gray-300 rounded-full p-2 cursor-pointer"
          >
            {proposal.proposal_power_id}
          </.badge>
        </:col>
      </.table>
    </div>
    """
  end

  @impl true
  def handle_event("update_filter", %{"filter" => filter_type}, socket) do
    socket =
      socket
      |> assign(:filter_type, filter_type)
      |> assign(:current_page, 1)
      |> reload_proposals()

    {:noreply, socket}
  end

  @impl true
  def handle_event("search", %{"search" => search}, socket) do
    socket =
      socket
      |> assign(:search, search)
      |> assign(:current_page, 1)
      |> reload_proposals()

    {:noreply, socket}
  end

  @impl true
  def handle_event("paginate", %{"page" => page}, socket) do
    page_number = String.to_integer(page)

    socket =
      socket
      |> assign(:current_page, page_number)
      |> reload_proposals(page: page_number)

    {:noreply, socket}
  end

  defp reload_proposals(socket, extra_params \\ []) do
    app_context = socket.assigns.app_context
    filter_type = socket.assigns.filter_type
    search = socket.assigns.search

    params = Enum.into(extra_params, %{})

    socket
    |> assign(:loading, true)
    |> start_async(:load_proposals, fn ->
      fetch_proposals(app_context, filter_type, search, params)
    end)
  end
end
