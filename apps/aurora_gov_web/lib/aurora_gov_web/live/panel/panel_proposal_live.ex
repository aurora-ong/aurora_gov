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
  def render(assigns) do
    ~H"""
    <section class="card w-full max-w-5xl flex flex-col h-fit justify-center items-center bg-white shadow-lg rounded-lg p-6">
      <div class="flex flex-col md:flex-row w-full justify-between items-center mb-4 gap-2">
        <div class="flex gap-2">
          <button
            class={"btn btn-sm " <> if @filter_type == "all", do: "btn-primary", else: "btn-outline"}
            phx-click="update_filter"
            phx-value-filter="all"
            phx-target={@myself}
          >
            Todas
          </button>

          <button
            class={"btn btn-sm " <> if @filter_type == "out", do: "btn-primary", else: "btn-outline"}
            phx-click="update_filter"
            phx-value-filter="out"
            phx-target={@myself}
          >
            De salida
          </button>

          <button
            class={"btn btn-sm " <> if @filter_type == "in", do: "btn-primary", else: "btn-outline"}
            phx-click="update_filter"
            phx-value-filter="in"
            phx-target={@myself}
          >
            Entrantes
          </button>
        </div>

        <form phx-change="search" phx-target={@myself} class="flex items-center gap-2">
          <input
            name="search"
            value={@search}
            placeholder="Buscar por título..."
            class="input input-bordered input-sm"
          />
        </form>
      </div>

      <div class="relative overflow-x-auto w-full rounded-lg border border-gray-200 bg-gray-50 min-h-[200px]">
        <%= if @loading do %>
          <.loading_spinner></.loading_spinner>
        <% else %>
          <.table id="proposals" rows={@streams.proposal_list}>
            <:col :let={{_id, proposal}} label="Título">
              {proposal.proposal_title}
            </:col>

            <:col :let={{_id, proposal}} label="Descripción">
              {proposal.proposal_description}
            </:col>

            <:col :let={{_id, proposal}} label="Tipo"></:col>

            <:col :let={{_id, proposal}} label="Fecha">
              {Timex.lformat!(proposal.created_at, "{0D}/{0M}/{YYYY} {h24}:{m}", "es")}
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
