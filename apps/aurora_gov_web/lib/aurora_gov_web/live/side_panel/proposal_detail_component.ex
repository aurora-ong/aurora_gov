defmodule AuroraGov.Web.Live.Panel.Side.ProposalDetail do
  alias AuroraGov.Web.Live.Panel.AppView
  use AuroraGov.Web, :live_component
  alias Phoenix.LiveView.AsyncResult
  require Logger

  defmodule Context do
    defstruct proposal: nil, voting_status: nil, current_vote: nil, allowed_to_vote: false
  end

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:context, AsyncResult.loading())
      |> assign(:active_tab, "info")

    {:ok, socket}
  end

  @impl true
  def update(%{update: {:vote_emited, %{proposal_id: proposal_id}}}, socket) do
    refresh_proposal(proposal_id, socket)
  end

  @impl true
  def update(%{update: {:proposal_executing, %{proposal_id: proposal_id}}}, socket) do
    refresh_proposal(proposal_id, socket)
  end

  @impl true
  def update(%{update: {:proposal_consumed, %{proposal_id: proposal_id}}}, socket) do
    refresh_proposal(proposal_id, socket)
  end

  defp refresh_proposal(proposal_id, socket) do
    socket =
      if proposal_id == socket.assigns.proposal_id do
        person_id =
          socket.assigns.app_context.current_person &&
            socket.assigns.app_context.current_person.person_id

        socket
        |> start_async(:load_context, fn -> load_context(proposal_id, person_id) end)
      else
        socket
      end

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    proposal_id = assigns[:proposal_id]
    person_id = assigns.app_context.current_person && assigns.app_context.current_person.person_id

    socket =
      socket
      |> assign(assigns)
      |> start_async(:load_context, fn -> load_context(proposal_id, person_id) end)

    {:ok, socket}
  end

  defp load_context(proposal_id, person_id) do
    :timer.sleep(250)

    with %AuroraGov.Projector.Model.Proposal{} = proposal <-
           AuroraGov.Context.ProposalContext.get_proposal_by_id(proposal_id),
         voting_status <- AuroraGov.Context.ProposalContext.calculate_voting_status(proposal),
         current_vote <-
           person_id &&
             AuroraGov.Context.ProposalContext.get_person_vote_from_proposal(
               proposal,
               person_id
             ) do
      %Context{
        proposal: proposal,
        voting_status: voting_status,
        current_vote: current_vote
      }
    else
      {:error, reason} ->
        {:error, reason}

      error ->
        Logger.error("Error #{inspect(error)}")
        {:error, "unknown error"}
    end
  end

  @impl true
  def handle_async(:load_context, {:ok, result}, socket) do
    case result do
      %Context{} = context ->
        {:noreply, assign(socket, :context, AsyncResult.ok(context))}

      {:error, reason} ->
        {:noreply,
         socket
         |> assign(:context, AsyncResult.failed(socket.assigns.context, reason))
         |> put_flash(:error, "Error cargando propuesta")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col h-full">
      <.async_result :let={context} assign={@context}>
        <:loading>
          <.loading_spinner size="double_large" />
        </:loading>

        <:failed :let={error}>
          <div class="text-center py-8 flex-1 flex flex-col justify-center items-center">
            <i class="fa-solid fa-exclamation-triangle text-4xl text-gray-300 mb-4"></i>
            <h3 class="text-lg font-medium text-gray-900 mb-2">Error al cargar</h3>

            <p class="text-gray-500">
              No se pudo cargar la información de esta propuesta. <br /> {inspect(error)}
            </p>
          </div>
        </:failed>

        <div class="mb-2">
          <div class="flex flex-wrap gap-2 mb-3">
            <%= if context.proposal.proposal_ou_start_id != context.proposal.proposal_ou_end_id do %>
              <.ou_id_badge
                ou_id={context.proposal.proposal_ou_start_id}
                ou_name={context.proposal.proposal_ou_start.ou_name}
                size="sm"
              />
              <span class="text-gray-400 flex items-center text-sm">
                <i class="fa fa-arrow-right"></i>
              </span>

              <.ou_id_badge
                ou_id={context.proposal.proposal_ou_end_id}
                ou_name={context.proposal.proposal_ou_end.ou_name}
                size="sm"
              />
            <% else %>
              <.ou_id_badge
                ou_id={context.proposal.proposal_ou_end_id}
                ou_name={context.proposal.proposal_ou_end.ou_name}
                size="sm"
              />
            <% end %>
          </div>

          <h2 class="text-xl font-bold text-gray-900 mb-2 m-0">
            {context.proposal.proposal_title}
          </h2>

          <.badge size="extra_small" variant="bordered" rounded="extra_large">
            {context.proposal.proposal_id}
          </.badge>
        </div>

    <!-- Tabs -->
        <div class="flex border-b border-gray-200 mb-4">
          <button
            phx-click="tab_change"
            phx-value-tab="info"
            phx-target={@myself}
            class={[
              "px-4 py-2 font-medium text-sm border-b-2 transition-colors",
              if(@active_tab == "info",
                do: "border-aurora_orange text-aurora_orange",
                else: "border-transparent text-gray-500 hover:text-gray-700"
              )
            ]}
          >
            <i class="fa-solid fa-info-circle mr-1"></i> Información
          </button>

          <button
            phx-click="tab_change"
            phx-value-tab="votes"
            phx-target={@myself}
            class={[
              "px-4 py-2 font-medium text-sm border-b-2 transition-colors",
              if(@active_tab == "votes",
                do: "border-aurora_orange text-aurora_orange",
                else: "border-transparent text-gray-500 hover:text-gray-700"
              )
            ]}
          >
            <i class="fa-solid fa-vote-yea mr-1"></i> Estado
          </button>

          <button
            phx-click="tab_change"
            phx-value-tab="discussion"
            phx-target={@myself}
            class={[
              "px-4 py-2 font-medium text-sm border-b-2 transition-colors",
              if(@active_tab == "discussion",
                do: "border-aurora_orange text-aurora_orange",
                else: "border-transparent text-gray-500 hover:text-gray-700"
              )
            ]}
          >
            <i class="fa-solid fa-comments mr-1"></i> Discusión
          </button>
        </div>

    <!-- Contenido de tabs -->
        <div class="flex-1">
          <%= case @active_tab do %>
            <% "info" -> %>
              <div class="space-y-4">
                <div>
                  <h3 class="font-semibold text-gray-900 mb-2">Descripción</h3>

                  <p class="text-gray-700 leading-relaxed">{context.proposal.proposal_description}</p>
                </div>

                <div>
                  <h3 class="font-semibold text-gray-900 mb-2">Detalles</h3>

                  <dl class="grid grid-cols-1 md:grid-cols-2 gap-x-8 gap-y-2">
                    <div>
                      <dt class="text-sm font-semibold text-gray-700">Propietario</dt>

                      <dd class="text-sm text-gray-900">
                        {context.proposal.proposal_owner.person_name}
                      </dd>
                    </div>

                    <div>
                      <dt class="text-sm font-semibold text-gray-700">Poder</dt>

                      <dd class="text-sm text-gray-900">{context.proposal.proposal_power_id}</dd>
                    </div>

                    <div>
                      <dt class="text-sm font-semibold text-gray-700">Estado</dt>

                      <dd class="text-sm text-gray-900 capitalize">
                        {context.proposal.proposal_status}
                      </dd>
                    </div>

                    <div>
                      <dt class="text-sm font-semibold text-gray-700">Creada</dt>

                      <dd class="text-sm text-gray-900">
                        {Timex.lformat!(
                          context.proposal.created_at,
                          "{0D}/{0M}/{YYYY} {h24}:{m}",
                          "es"
                        )}
                      </dd>
                    </div>
                  </dl>
                </div>

                <%= if context.proposal.proposal_power_data && map_size(context.proposal.proposal_power_data) > 0 do %>
                  <div>
                    <h3 class="font-semibold text-gray-900 mb-2">Datos del Poder</h3>
                     <pre class="bg-gray-100 p-3 rounded text-xs overflow-x-auto">
                        {Jason.encode!(context.proposal.proposal_power_data, pretty: true)}
                      </pre>
                  </div>
                <% end %>
              </div>
            <% "votes" -> %>
              <div class="flex flex-col h-full">
                <div class="space-y-3 flex-1 overflow-auto">
                  <%= for {ou_id, status} <- context.voting_status do %>
                    <div class="bg-gray-50 p-3 rounded-lg border">
                      <div class="flex items-center justify-between mb-2">
                        <.ou_id_badge ou_id={ou_id} size="sm" />
                        <span class="text-sm text-gray-600">
                          {status[:current_voters]} / {status[:total_voters]} votos
                        </span>
                      </div>

                      <.proposal_vote_progress
                        current_score={status[:current_score]}
                        required_score={status[:required_score]}
                      />
                    </div>
                  <% end %>
                </div>

                <%= if @app_context && @app_context.current_person && @app_context.current_person.person_id == context.proposal.proposal_owner_id && context.proposal.proposal_status == :active do %>
                  <hr class="my-5" />
                  <div class="text-center">
                    <button
                      phx-click="execute_proposal"
                      phx-value-proposal-id={context.proposal.proposal_id}
                      phx-target={@myself}
                      class="primary filled w-full"
                    >
                      <i class="fa-solid fa-bolt"></i> Ejecutar
                    </button>
                  </div>
                <% end %>
              </div>
            <% "discussion" -> %>
              <div class="flex flex-col h-full">
                <div
                  :if={context.proposal.proposal_votes && length(context.proposal.proposal_votes) > 0}
                  class="space-y-2 flex-1"
                >
                  <%= for vote <- context.proposal.proposal_votes do %>
                    <div class="bg-gray-50 p-2 rounded text-sm">
                      <div class="flex justify-between items-center">
                        <span class="font-medium">{vote.person_id}</span>
                        <span class={[
                          "px-2 py-1 rounded text-xs font-medium",
                          case vote.vote_value do
                            1 ->
                              "bg-green-100 text-green-800"

                            0 ->
                              "bg-gray-100 text-gray-800"

                            -1 ->
                              "bg-red-100 text-red-800"

                            nil ->
                              if context.proposal.proposal_status == :active,
                                do: "bg-yellow-100 text-yellow-800",
                                else: "bg-gray-100 text-gray-800"
                          end
                        ]}>
                          <%= case vote.vote_value do %>
                            <% 1 -> %>
                              <i class="fa-solid fa-check text-green-600 mr-1"></i> A favor
                            <% 0 -> %>
                              <i class="fa-solid fa-equals text-gray-600 mr-1"></i> Abstención
                            <% -1 -> %>
                              <i class="fa-solid fa-times text-red-600 mr-1"></i> En contra
                            <% nil -> %>
                              <%= if context.proposal.proposal_status == :active do %>
                                <i class="fa-solid fa-hourglass-half text-yellow-600 mr-1"></i>
                                Pendiente
                              <% else %>
                                <i class="text-gray-600 mr-1"></i> No votó
                              <% end %>
                          <% end %>
                        </span>
                      </div>
                    </div>
                  <% end %>
                </div>

                <%= if context.proposal.proposal_status == :active do %>
                  <hr class="border-gray-100 border my-2" />
                  <.button
                    disabled={context.current_vote == nil}
                    display="flex"
                    rounded="extra_large"
                    phx-click="update_vote"
                    phx-value-proposal-id={context.proposal.proposal_id}
                    phx-target={@myself}
                  >
                    <i class="fa-solid fa-vote-yea"></i> {if context.current_vote &&
                                                               context.current_vote.updated_at !=
                                                                 nil,
                                                             do: "Actualizar voto",
                                                             else: "Votar"}
                  </.button>

                  <%!-- <div class="text-center">
                    <button class="primary filled w-full">
                      <i class="fa-solid fa-vote-yea"></i> {if context.current_vote &&
                                                                 context.current_vote.updated_at !=
                                                                   nil,
                                                               do: "Actualizar voto",
                                                               else: "Votar"}
                    </button>
                  </div> --%>
                <% end %>
              </div>
          <% end %>
        </div>
      </.async_result>
    </div>
    """
  end

  @impl true
  def handle_event("tab_change", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, :active_tab, tab)}
  end

  @impl true
  def handle_event("update_vote", %{"proposal-id" => proposal_id}, socket) do
    IO.inspect(proposal_id, label: "update_vote")

    app_view = %AppView{
      view_id: "modal-proposal_vote",
      view_module: AuroraGov.Web.Live.Proposal.VoteModal,
      view_options: %{
        modal_size: "double_large"
      },
      view_params: %{
        proposal_id: proposal_id
      }
    }

    send(self(), {:open, :app_modal, app_view})

    {:noreply, socket}
  end

  @impl true
  def handle_event("execute_proposal", %{"proposal-id" => proposal_id}, socket) do
    IO.inspect(proposal_id, label: "execute_vote")

    app_view = %AppView{
      view_id: "modal-execute_proposal",
      view_module: AuroraGov.Web.Live.Proposal.ExecuteModal,
      view_options: %{
        modal_size: "double_large"
      },
      view_params: %{
        proposal_id: proposal_id
      }
    }

    send(self(), {:open, :app_modal, app_view})

    {:noreply, socket}
  end
end
