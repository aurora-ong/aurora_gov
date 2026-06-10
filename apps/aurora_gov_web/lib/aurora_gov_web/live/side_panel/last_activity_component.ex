defmodule AuroraGov.Web.Live.Panel.Side.LastActivity do
  alias AuroraGov.Event.MembershipPromoted
  use AuroraGov.Web, :live_component
  alias Phoenix.LiveView.AsyncResult
  alias AuroraGov.Context.BlockchainContext
  require Logger

  # Aliases para hacer el pattern matching más limpio
  alias AuroraGov.Event.{
    VoteEmited,
    ProposalCreated,
    OUCreated,
    MembershipStarted,
    PowerUpdated,
    PersonRegistered,
    ProposalExecuted,
    ProposalConsumed,
    PowerDelegationActivated,
    PowerDelegationDeactivated
  }

  alias AuroraGov.Projector.Model.{Person, OU}

  # 1. ACTUALIZACIÓN DE ESTADO: Añadimos paginación
  defmodule Context do
    defstruct activity_list: [], page: 1, has_more: true, loading_more: false
  end

  @impl true
  def mount(socket) do
    {:ok, assign(socket, :context, AsyncResult.loading())}
  end

  @impl true
  def update(assigns, socket) do
    ou_id = assigns.app_context.current_ou_id

    socket =
      socket
      |> assign(assigns)
      |> assign(:ou_id, ou_id)
      |> start_async(:load_initial, fn -> load_page(ou_id, 1) end)

    {:ok, socket}
  end

  # 3. MANEJO DEL EVENTO DE SCROLL
  @impl true
  def handle_event("load_more", _params, socket) do
    case socket.assigns.context do
      %AsyncResult{
        result: %Context{loading_more: false, has_more: true, page: current_page} = ctx
      } ->
        socket = assign(socket, :context, AsyncResult.ok(%{ctx | loading_more: true}))

        ou_id = socket.assigns.ou_id


        {:noreply,
         start_async(socket, :load_more_async, fn ->
           load_page(ou_id, current_page + 1)
         end)}

      _ ->
        {:noreply, socket}
    end
  end

  defp load_page(nil, _page), do: {[], 1, false}

  defp load_page(ou_id, page) do
    params = %{page: page, page_size: 10, order_by: [:index], order_directions: [:desc]}

    case BlockchainContext.list_timeline(ou_id, params) do
      {:ok, {blocks, meta}} ->
        has_more = meta.next_page != nil
        {blocks, page, has_more}

      {:error, reason} ->
        Logger.error("Error cargando timeline pg #{page}: #{inspect(reason)}")
        {[], page, false}
    end
  end

  @impl true
  def handle_async(:load_initial, {:ok, {blocks, page, has_more}}, socket) do
    ctx = %Context{
      activity_list: blocks,
      page: page,
      has_more: has_more,
      loading_more: false
    }

    {:noreply, assign(socket, :context, AsyncResult.ok(ctx))}
  end

  @impl true
  def handle_async(:load_more_async, {:ok, {new_blocks, new_page, has_more}}, socket) do
    current_ctx = socket.assigns.context.result

    updated_ctx = %{
      current_ctx
      | activity_list: current_ctx.activity_list ++ new_blocks,
        page: new_page,
        has_more: has_more,
        loading_more: false
    }

    {:noreply, assign(socket, :context, AsyncResult.ok(updated_ctx))}
  end

  @impl true
  def handle_async(_name, {:exit, reason}, socket) do
    {:noreply, assign(socket, :context, AsyncResult.failed(socket.assigns.context, reason))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col h-full">
      <.async_result :let={context} assign={@context}>
        <:loading>
          <div class="flex justify-center p-8"><.loading_spinner size="double_large" /></div>
        </:loading>

        <:failed :let={error}>
          <div class="text-center py-8 flex-1 flex flex-col justify-center items-center">
            <i class="fa-solid fa-exclamation-triangle text-4xl text-gray-300 mb-4"></i>
            <h3 class="text-lg font-medium text-gray-900 mb-2">No se pudo cargar</h3>

            <p class="text-gray-500 text-xs truncate max-w-xs">{inspect(error)}</p>
          </div>
        </:failed>

        <h3 class="text-2xl font-semibold text-blue-700 mb-4 px-1 flex flex-row justify-between items-center">
          Última actividad
        </h3>

        <div
          id="activity-scroll-container"
          class="flex flex-col gap-3 overflow-y-auto pr-1 custom-scrollbar flex-1"
        >
          <%= if Enum.empty?(context.activity_list) do %>
            <div class="text-gray-500 text-sm italic p-3 text-center border border-dashed rounded bg-gray-50">
              No hay actividad reciente en esta organización.
            </div>
          <% else %>
            <%= for block <- context.activity_list do %>
              <.link navigate={render_link(block)}>
                <div
                  id={"block-#{block.index}"}
                  class="bg-white rounded-lg shadow-sm p-3 border border-gray-200 transition hover:shadow-md hover:border-blue-300 relative group cursor-pointer"
                >
                  <div class="absolute left-0 top-0.5 bottom-0.5 w-1 rounded-r bg-gray-300 group-hover:bg-blue-500">
                  </div>

                  <div class="pl-2 flex items-start justify-between gap-2">
                    <div class="flex-1 min-w-0">
                      <div class="flex items-center gap-2 mb-1">
                        <span class="text-xs text-gray-400 font-mono">
                          {format_date(block.occurred_at)}
                        </span>
                        <span class="text-xs px-1.5 py-0.5 rounded-full font-medium bg-gray-100 text-gray-600 opacity-0 group-hover:opacity-100 group-hover:text-blue-400 transition-colors">
                          {humanize_event_type(block)}
                        </span>
                      </div>

                      <div class="text-sm text-gray-800 font-medium leading-tight line-clamp-3">
                        {render_description(block)}
                      </div>
                    </div>

                    <div class="flex flex-col items-end gap-0.5">
                      <span
                        class="text-xs font-semibold font-mono px-1 text-gray-600 group-hover:text-blue-400 transition-colors bg-gray-50 border rounded-sm"
                        title="Block Height"
                      >
                        #{block.index}
                      </span>
                      <span
                        class="text-xs font-semibold font-mono px-1 text-gray-600 group-hover:text-blue-400 transition-colors bg-gray-50 border rounded-sm"
                        title={String.downcase(block.hash)}
                      >
                        {String.slice(String.downcase(block.hash), 1..10)}
                      </span>
                    </div>
                  </div>
                </div>
              </.link>
            <% end %>

            <div
              :if={context.has_more}
              id="infinite-scroll-sentinel"
              phx-hook="InfiniteScroll"
              phx-target={@myself}
              class="h-4 w-full"
            >
              <.loading_spinner size="small" />
              <.loading_spinner size="small" />
            </div>
          <% end %>
        </div>
      </.async_result>
    </div>
    """
  end

  defp format_date(nil), do: "-"

  defp format_date(date) do
    Calendar.strftime(date, "%d %b · %H:%M")
  end

  defp render_description(%{
         data: %PowerDelegationActivated{
           power_id: power_id
         },
         person: %Person{person_name: person_name},
         ou: %OU{ou_name: ou_name}
       }) do
    "#{person_name} ha delegado su poder #{power_id} en #{ou_name}"
  end

  defp render_description(%{
         data: %PowerDelegationDeactivated{
           power_id: power_id
         },
         person: %Person{person_name: person_name},
         ou: %OU{ou_name: ou_name}
       }) do
    "#{person_name} ha dejado de delegar su poder #{power_id} en #{ou_name}"
  end

  defp render_description(%{data: %VoteEmited{vote_value: val, vote_comment: comment}}) do
    vote_text = if val > 0, do: "A favor", else: "En contra"

    if comment && comment != "" do
      "Votó #{vote_text}: \"#{truncate(comment, 40)}\""
    else
      "Votó #{vote_text} en la propuesta"
    end
  end

  defp render_description(%{
         data: %ProposalCreated{proposal_title: title, proposal_ou_end_id: proposal_ou_end_id}
       }) do
    "Nueva propuesta: #{title} publicada en #{proposal_ou_end_id}"
  end

  defp render_description(%{data: %ProposalExecuted{proposal_id: proposal_id}}) do
    "Propuesta #{proposal_id} fue ejecutada."
  end

  defp render_description(%{
         data: %ProposalConsumed{proposal_id: proposal_id, proposal_execution_result: "success"}
       }) do
    "La propuesta #{proposal_id} fue consumida con éxito."
  end

  defp render_description(%{
         data: %ProposalConsumed{proposal_id: proposal_id, proposal_execution_result: "failed"}
       }) do
    "La propuesta #{proposal_id} fue consumida con error."
  end

  defp render_description(%{data: %OUCreated{ou_id: ou_id, ou_name: name}}) do
    "Se ha creado una nueva unidad #{name} (#{ou_id})"
  end

  defp render_description(%{
         data: %MembershipStarted{},
         person: %Person{person_name: person_name},
         ou: %OU{ou_name: ou_name}
       }) do
    "#{person_name} ha iniciado una membresia en #{ou_name}"
  end

  defp render_description(%{
         data: %MembershipPromoted{membership_rank: membership_rank, ou_id: _ou_id},
         person: %Person{person_name: person_name},
         ou: %OU{ou_name: ou_name}
       }) do
    "#{person_name} ahora es #{membership_rank} en #{ou_name}"
  end

  defp render_description(%{
         data: %PowerUpdated{power_id: power_id, power_value: val, ou_id: _ou_id},
         ou: %OU{ou_name: ou_name},
         person: %Person{person_name: person_name}
       }) do
    "#{person_name} actualizó su poder #{power_id} de voto en #{ou_name} a #{val} puntos"
  end

  defp render_description(%{data: %PersonRegistered{person_name: person_name}}) do
    "#{person_name} se ha registrado"
  end

  defp render_description(%{data: %{__struct__: _} = data}) do
    Map.get(data, :name) || Map.get(data, :title) || ""
  end

  defp render_description(%{data: %{} = data}) do
    data["proposal_title"] || data["ou_name"] || "Evento registrado"
  end

  defp render_description(_), do: "Información no disponible"

  defp render_link(%{data: %ProposalCreated{proposal_id: proposal_id}}),
    do: ~p"/app/proposals/#{proposal_id}"

  defp render_link(%{data: %ProposalExecuted{proposal_id: proposal_id}}),
    do: ~p"/app//proposals/#{proposal_id}"

  defp render_link(%{data: %ProposalConsumed{proposal_id: proposal_id}}),
    do: ~p"/app//proposals/#{proposal_id}"

  defp render_link(_), do: ""

  defp humanize_event_type(block) do
    block.event_type
    |> String.split(".")
    |> List.last()
    |> String.replace("Event", "")
  end

  defp truncate(text, len) do
    if String.length(text) > len, do: String.slice(text, 0, len) <> "...", else: text
  end
end
