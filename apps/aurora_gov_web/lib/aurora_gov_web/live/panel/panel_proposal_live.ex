defmodule AuroraGovWeb.Live.Panel.Proposals do
  use AuroraGovWeb, :live_component
  import Flop.Phoenix, only: [pagination_links: 2]

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:filter_type, "all")
      |> assign(:search, "")
      |> assign(:meta, nil)
      |> assign(:loading, true)
      |> stream_configure(:proposal_list, dom_id: & &1.proposal_id)
      |> stream(:proposal_list, [])

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    filter_type = socket.assigns[:filter_type] || "all"
    filter_search = socket.assigns[:search] || ""
    params = assigns[:params] || %{}
    IO.inspect(params, label: "Params")

    socket =
      socket
      |> assign(:context, assigns.context)
      |> assign(:loading, true)
      |> start_async(:load_proposals, fn ->
        fetch_proposals(assigns.context, filter_type, filter_search, params)
      end)

    {:ok, socket}
  end

  defp fetch_proposals(context, filter_type, search, params) do
    filters =
      case filter_type do
        "all" ->
          [
            %{field: :proposal_ou_start_id, op: :==, value: context},
            %{field: :proposal_ou_end_id, op: :==, value: context, or: true}
          ]

        "out" ->
          [%{field: :proposal_ou_start_id, op: :==, value: context}]

        "in" ->
          [%{field: :proposal_ou_end_id, op: :==, value: context}]

        _ ->
          []
      end

    filters =
      if search != "",
        do: filters ++ [%{field: :proposal_title, op: :ilike, value: "%" <> search <> "%"}],
        else: filters

    filters = [
      %{field: :proposal_ou_end_id, op: :==, value: context}
    ]

    IO.inspect(filters)
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
      |> assign(:meta, meta)
      |> stream(:proposal_list, proposals, reset: true)

    {:noreply, socket}
  end

  @impl true
  def handle_event("update_filter", %{"filter" => filter_type}, socket) do
    filter_search = socket.assigns[:search] || ""
    context = socket.assigns.context

    socket =
      socket
      |> assign(:filter_type, filter_type)
      |> assign(:loading, true)
      |> start_async(:load_proposals, fn ->
        fetch_proposals(context, filter_type, filter_search, %{})
      end)

    {:noreply, socket}
  end

  @impl true
  def handle_event("search", %{"search" => search}, socket) do
    socket =
      socket
      |> assign(:search, search)
      |> assign(:loading, true)
      |> start_async(:load_proposals, fn ->
        fetch_proposals(socket.assigns.context, socket.assigns.filter_type, search, %{})
      end)

    {:noreply, socket}
  end

  @impl true
  def handle_event("paginate", %{"page" => page}, socket) do
    params = %{page: String.to_integer(page)}

    socket =
      socket
      |> assign(:loading, true)
      |> start_async(:load_proposals, fn ->
        fetch_proposals(
          socket.assigns.context,
          socket.assigns.filter_type,
          socket.assigns.search,
          params
        )
      end)

    {:noreply, socket}
  end

  @impl true
  def handle_event("proposal_row_click", %{"id" => proposal_id}, socket) do
    # Aquí puedes abrir el panel lateral, cargar detalles, etc.
    IO.inspect(proposal_id, label: "Fila clickeada")

    {:noreply,
     assign(socket,
       side_panel_open: true
     )}

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <section class="card w-full max-w-5xl flex flex-col justify-center items-center bg-white shadow-lg rounded-lg p-6 overflow-y-auto">
      <div class="flex flex-col md:flex-row w-full justify-between items-center mb-4 gap-2">
        <div class="flex gap-2">
          <.filter_button_group
            options={[
              %{label: "Todas", value: :all},
              %{label: "Internas", value: :internal},
              %{label: "Entrantes", value: :in},
              %{label: "Salientes", value: :out}
            ]}
            selected={:all}
            on_select="filter_changed"
          />
        </div>

        <form phx-change="search" phx-target={@myself} class="flex items-center gap-2">
          <.search_field name="search" value={@search} placeholder="Búsqueda rápida" />
        </form>
      </div>

      <div class="relative overflow-x-auto w-full rounded-lg border border-gray-200 bg-gray-50 min-h-[200px]">
        <%= if @loading do %>
          <.loading_spinner size="double_large" />
        <% else %>
          <.table
            id="proposals"
            rows={@streams.proposal_list}
            row_click={
              fn {_id, proposal} ->
                JS.push("open_side_panel",
                  value: %{
                    component: AuroraGovWeb.Live.Panel.Side.ProposalDetail,
                    assigns: %{proposal_id: proposal.proposal_id}
                  }
                )
              end
            }
          >
            <:col :let={{_id, proposal}} label="Título" class="w-10">
              <div class="flex-col flex">
                <div class="flex-row flex">
                  <%= if proposal.proposal_ou_start_id != proposal.proposal_ou_end_id do %>
                    <.ou_id_badge
                      ou_id={proposal.proposal_ou_start_id}
                      ou_name={proposal.proposal_ou_start.ou_name}
                    />
                    <span class="mx-2 text-gray-400 flex items-center">
                      <i class="fa fa-arrow-right"></i>
                    </span>

                    <.ou_id_badge
                      ou_id={proposal.proposal_ou_end_id}
                      ou_name={proposal.proposal_ou_end.ou_name}
                    />
                  <% else %>
                    <.ou_id_badge
                      ou_id={proposal.proposal_ou_end_id}
                      ou_name={proposal.proposal_ou_end.ou_name}
                    />
                  <% end %>
                </div>

                <h3 class="text-lg text-black">{proposal.proposal_title}</h3>

                <p class="text-md text-gray-600 font-normal">{proposal.proposal_description}</p>
              </div>
            </:col>

            <:col :let={{_id, proposal}} label="Estado">
              {inspect(AuroraGov.Context.ProposalContext.calculate_voting_status(proposal))}
              <.voting_progress_simple voting_map={
                AuroraGov.Context.ProposalContext.calculate_voting_status(proposal)
              } />
              <%!-- <.voting_progress_full voting_map={
                AuroraGov.Context.ProposalContext.calculate_voting_status(proposal)
              } /> --%>
              <%!-- <.progress class="w-96 h-50">
                <.progress_section class="bg-orange-600 text-white" value={60}>
                  <:tooltip label="Images" position="top" class="font-bold">
                    Tooltip content for Images
                  </:tooltip>
                </.progress_section>

                <.progress_section class="bg-red-600" value={10}>
                  <:tooltip label="15%" position="bottom" class="text-white text-sm bg-black">
                    Only 5% left
                  </:tooltip>
                </.progress_section>

                <.progress_section color="misc" class="bg-blue-600 text-white" value={30}>
                  <:tooltip label="Other" position="top" clickable={true} class="font-bold">
                    This section represents other files
                  </:tooltip>
                </.progress_section>
              </.progress> --%> {Timex.lformat!(
                proposal.created_at,
                "{0D}/{0M}/{YYYY} {h24}:{m}",
                "es"
              )} {proposal.proposal_owner.person_name} {proposal.proposal_power_id} {proposal.proposal_status}
            </:col>
          </.table>

          <%= if @meta do %>
            <div class="mt-4 flex justify-center"></div>
          <% end %>
        <% end %>
      </div>
    </section>
    """
  end
end
