defmodule AuroraGovWeb.Live.Panel.Side.ProposalDetail do
  use AuroraGovWeb, :live_component

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:proposal, nil)
      |> assign(:loading, true)
      |> assign(:active_tab, "info")
      |> assign(:voting_status, %{})

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    proposal_id = assigns[:proposal_id]

    socket =
      socket
      |> assign(assigns)
      |> assign(:proposal_id, proposal_id)
      |> assign(:loading, true)
      |> start_async(:load_proposal, fn -> load_proposal_data(proposal_id) end)

    {:ok, socket}
  end

  @impl true
  def handle_async(:load_proposal, {:ok, {proposal, voting_status}}, socket) do
    {:noreply,
     socket
     |> assign(:proposal, proposal)
     |> assign(:voting_status, voting_status)
     |> assign(:loading, false)}
  end

  @impl true
  def handle_async(:load_proposal, {:exit, reason}, socket) do
    {:noreply,
     socket
     |> assign(:loading, false)
     |> put_flash(:error, "Error cargando propuesta: #{inspect(reason)}")}
  end

  @impl true
  def handle_event("tab_change", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, :active_tab, tab)}
  end

  defp load_proposal_data(proposal_id) do
    case AuroraGov.Context.ProposalContext.get_proposal_by_id(proposal_id) do
      {:ok, proposal} ->
        voting_status = AuroraGov.Context.ProposalContext.calculate_voting_status(proposal)
        {proposal, voting_status}

      {:error, _reason} ->
        {nil, %{}}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col h-full">
      <%= if @loading do %>
        <.loading_spinner size="medium" class="py-8" />
      <% else %>
        <%= if @proposal do %>
          <!-- Header con título y badges -->
          <div class="mb-2">
            <div class="flex flex-wrap gap-2 mb-3">
              <%= if @proposal.proposal_ou_start_id != @proposal.proposal_ou_end_id do %>
                <.ou_id_badge
                  ou_id={@proposal.proposal_ou_start_id}
                  ou_name={@proposal.proposal_ou_start.ou_name}
                  size="sm"
                />
                <span class="text-gray-400 flex items-center text-sm">
                  <i class="fa fa-arrow-right"></i>
                </span>

                <.ou_id_badge
                  ou_id={@proposal.proposal_ou_end_id}
                  ou_name={@proposal.proposal_ou_end.ou_name}
                  size="sm"
                />
              <% else %>
                <.ou_id_badge
                  ou_id={@proposal.proposal_ou_end_id}
                  ou_name={@proposal.proposal_ou_end.ou_name}
                  size="sm"
                />
              <% end %>
            </div>

            <h2 class="text-xl font-bold text-gray-900 mb-2">
              {@proposal.proposal_title}
            </h2>
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

                    <p class="text-gray-700 leading-relaxed">{@proposal.proposal_description}</p>
                  </div>

                  <div>
                    <h3 class="font-semibold text-gray-900 mb-2">Detalles</h3>

                    <dl class="grid grid-cols-1 md:grid-cols-2 gap-x-8 gap-y-2">
                      <div>
                        <dt class="text-sm font-semibold text-gray-700">Propietario</dt>

                        <dd class="text-sm text-gray-900">{@proposal.proposal_owner.person_name}</dd>
                      </div>

                      <div>
                        <dt class="text-sm font-semibold text-gray-700">Poder</dt>

                        <dd class="text-sm text-gray-900">{@proposal.proposal_power_id}</dd>
                      </div>

                      <div>
                        <dt class="text-sm font-semibold text-gray-700">Estado</dt>

                        <dd class="text-sm text-gray-900 capitalize">{@proposal.proposal_status}</dd>
                      </div>

                      <div>
                        <dt class="text-sm font-semibold text-gray-700">Creada</dt>

                        <dd class="text-sm text-gray-900">
                          {Timex.lformat!(@proposal.created_at, "{0D}/{0M}/{YYYY} {h24}:{m}", "es")}
                        </dd>
                      </div>
                    </dl>
                  </div>

                  <%= if @proposal.proposal_power_data && map_size(@proposal.proposal_power_data) > 0 do %>
                    <div>
                      <h3 class="font-semibold text-gray-900 mb-2">Datos del Poder</h3>
                       <pre class="bg-gray-100 p-3 rounded text-xs overflow-x-auto">
                        {Jason.encode!(@proposal.proposal_power_data, pretty: true)}
                      </pre>
                    </div>
                  <% end %>
                </div>
              <% "votes" -> %>
                <div class="space-y-4">
                  <div class="space-y-3">
                    <%= for {ou_id, status} <- @voting_status do %>
                      <div class="bg-gray-50 p-3 rounded-lg border">
                        <div class="flex items-center justify-between mb-2">
                          <.ou_id_badge ou_id={ou_id} size="sm" />
                          <span class="text-sm text-gray-600">
                            {status[:current_voters]} / {status[:total_voters]} votos
                          </span>
                        </div>

                        <.progress size="medium">
                          <.progress_section class="bg-green-600" color="#000000" value={100}>
                            <:label class="font-bold">
                              {status[:current_score]} / {status[:required_score]}
                            </:label>
                          </.progress_section>
                        </.progress>
                      </div>
                    <% end %>
                  </div>
                </div>
              <% "discussion" -> %>
                <div class="space-y-4">
                  <div class="text-center">
                    <%= if @proposal.proposal_votes && length(@proposal.proposal_votes) > 0 do %>
                      <div>
                        <div class="space-y-2">
                          <%= for vote <- @proposal.proposal_votes do %>
                            <div class="bg-gray-50 p-2 rounded text-sm">
                              <div class="flex justify-between items-center">
                                <span class="font-medium">{vote.person_id}</span>
                                <span class={[
                                  "px-2 py-1 rounded text-xs font-medium",
                                  case vote.vote_value do
                                    1 -> "bg-green-100 text-green-800"
                                    0 -> "bg-gray-100 text-gray-800"
                                    -1 -> "bg-red-100 text-red-800"
                                    nil -> "bg-yellow-100 text-yellow-800"
                                  end
                                ]}>
                                  <%= case vote.vote_value do %>
                                    <% 1 -> %>
                                      <i class="fa-solid fa-check text-green-600 mr-1"></i> A favor
                                    <% 0 -> %>
                                      <i class="fa-solid fa-equals text-gray-600 mr-1"></i> Neutro
                                    <% -1 -> %>
                                      <i class="fa-solid fa-times text-red-600 mr-1"></i> En contra
                                    <% nil -> %>
                                      <i class="fa-solid fa-hourglass-half text-yellow-600 mr-1"></i>
                                      Pendiente
                                  <% end %>
                                </span>
                              </div>
                            </div>
                          <% end %>
                        </div>
                         <hr class="my-5" />
                        <%= if @proposal.proposal_status == :active do %>
                          <div class="mb-4 text-center">
                            <button
                              phx-click="vote"
                              phx-value-proposal-id={@proposal.proposal_id}
                              phx-target={@myself}
                              class="primary filled w-full"
                            >
                              <i class="fa-solid fa-vote-yea"></i> Votar
                            </button>
                          </div>
                        <% end %>
                      </div>
                    <% end %>
                  </div>
                </div>
            <% end %>
          </div>
        <% else %>
          <div class="text-center py-8">
            <i class="fa-solid fa-exclamation-triangle text-4xl text-gray-300 mb-4"></i>
            <h3 class="text-lg font-medium text-gray-900 mb-2">Propuesta no encontrada</h3>

            <p class="text-gray-500">
              No se pudo cargar la información de esta propuesta.
            </p>
          </div>
        <% end %>
      <% end %>
    </div>
    """
  end
end
