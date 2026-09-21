defmodule AuroraGov.Web.Live.Panel.Side.MemberDetail do
  use AuroraGov.Web, :live_component
  alias Phoenix.LiveView.AsyncResult
  import Ecto.Query
  alias AuroraGov.Projector.Repo
  require Logger

  defmodule Context do
    defstruct person: nil, memberships: [], roles: [], proposals: []
  end

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:context, AsyncResult.loading())
      |> assign(:active_tab, "units")

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    person_id = assigns[:person_id]
    current_ou_id = assigns.app_context.current_ou_id

    socket =
      if person_id == socket.assigns[:person_id] and current_ou_id == socket.assigns[:current_ou_id] do
        socket
      else
        socket
        |> assign(assigns)
        |> assign(:person_id, person_id)
        |> assign(:current_ou_id, current_ou_id)
        |> assign(:context, AsyncResult.loading())
        |> start_async(:load_person_data, fn ->
          person = AuroraGov.Context.PersonContext.get_person!(person_id)

          memberships_query =
            from m in AuroraGov.Projector.Model.Membership,
              where: m.person_id == ^person_id,
              preload: [:ou]
          memberships = Repo.all(memberships_query)

          proposals_query =
            from p in AuroraGov.Projector.Model.Proposal,
              where: p.proposal_owner_id == ^person_id and (p.proposal_ou_start_id == ^current_ou_id or p.proposal_ou_end_id == ^current_ou_id),
              order_by: [desc: p.created_at]
          proposals = Repo.all(proposals_query)

          roles_query =
            from r in AuroraGov.Projector.Model.OURole,
              join: a in AuroraGov.Projector.Model.OURoleAssignment,
              on: r.role_id == a.role_id,
              where: a.person_id == ^person_id and a.ou_id == ^current_ou_id
          roles = Repo.all(roles_query)

          %Context{
            person: person,
            memberships: memberships,
            proposals: proposals,
            roles: roles
          }
        end)
      end

    {:ok, socket}
  end

  @impl true
  def handle_async(:load_person_data, {:ok, %Context{} = context}, socket) do
    {:noreply, assign(socket, :context, AsyncResult.ok(socket.assigns.context, context))}
  end

  def handle_async(:load_person_data, {:exit, reason}, socket) do
    Logger.error("Error al cargar persona: #{inspect(reason)}")
    {:noreply, assign(socket, :context, AsyncResult.failed(socket.assigns.context, reason))}
  end

  @impl true
  def handle_event("tab_change", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, :active_tab, tab)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col h-full">
      <.async_result :let={context} assign={@context}>
        <:loading><.loading_spinner size="double_large" /></:loading>

        <:failed :let={_error}>
          <div class="text-center py-8 flex-1 flex flex-col justify-center items-center">
            <i class="fa-solid fa-exclamation-triangle text-4xl text-gray-300 mb-4"></i>
            <h3 class="text-lg font-medium text-gray-900 mb-2">Error al cargar</h3>
            <p class="text-gray-500 max-w-sm mx-auto">
              No se pudo cargar la información del miembro.
            </p>
          </div>
        </:failed>

        <!-- Header del Miembro -->
        <div class="px-6 py-5 border-b border-gray-200 bg-white sticky top-0 z-10 shrink-0">
          <div class="flex justify-between items-start pr-8">
            <div class="flex items-center gap-3">
              <div class="w-12 h-12 rounded-full bg-blue-100 flex items-center justify-center text-blue-600">
                <i class="fa-regular fa-user text-2xl"></i>
              </div>
              <div>
                <h2 class="text-xl font-bold text-gray-900">
                  {context.person.person_name}
                </h2>
                <p class="text-sm text-gray-500 flex items-center gap-2">
                  <i class="fa-regular fa-envelope"></i> {context.person.person_mail}
                </p>
                <div class="flex items-center gap-4 mt-2">
                  <div class="flex items-center gap-2">
                    <.person_id_badge id={context.person.person_id} />
                  </div>

                  <div class="flex items-center gap-1.5 text-xs text-gray-500">
                    <i class="fa-regular fa-calendar-days"></i>
                    <span>Registrado el {Timex.lformat!(context.person.created_at, "{0D}/{0M}/{YYYY}", "es")}</span>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- Tabs -->
          <div class="flex gap-4 mt-6 border-b border-gray-200">
            <button
              phx-click="tab_change"
              phx-value-tab="units"
              phx-target={@myself}
              class={[
                "px-4 py-2 font-medium text-sm border-b-2 transition-colors",
                if(@active_tab == "units",
                  do: "border-aurora_orange text-aurora_orange",
                  else: "border-transparent text-gray-500 hover:text-gray-700"
                )
              ]}
            >
              <i class="fa-solid fa-sitemap mr-1"></i> Unidades
            </button>
            <button
              phx-click="tab_change"
              phx-value-tab="roles"
              phx-target={@myself}
              class={[
                "px-4 py-2 font-medium text-sm border-b-2 transition-colors",
                if(@active_tab == "roles",
                  do: "border-aurora_orange text-aurora_orange",
                  else: "border-transparent text-gray-500 hover:text-gray-700"
                )
              ]}
            >
              <i class="fa-solid fa-user-tag mr-1"></i> Roles
            </button>
            <button
              phx-click="tab_change"
              phx-value-tab="proposals"
              phx-target={@myself}
              class={[
                "px-4 py-2 font-medium text-sm border-b-2 transition-colors",
                if(@active_tab == "proposals",
                  do: "border-aurora_orange text-aurora_orange",
                  else: "border-transparent text-gray-500 hover:text-gray-700"
                )
              ]}
            >
              <i class="fa-solid fa-file-signature mr-1"></i> Propuestas
            </button>
          </div>
        </div>

        <!-- Contenido -->
        <div class="flex-1 overflow-y-auto p-6 bg-gray-50">
          <%= case @active_tab do %>
            <% "units" -> %>
              <div class="space-y-4">
                <%= if context.memberships == [] do %>
                  <div class="text-center py-8">
                    <p class="text-gray-500">No pertenece a ninguna unidad.</p>
                  </div>
                <% else %>
                  <%= for membership <- context.memberships do %>
                    <div
                      class={[
                        "p-4 rounded-xl border shadow-sm flex flex-col gap-3 transition cursor-pointer",
                        if(membership.ou_id == @current_ou_id, do: "bg-blue-50 border-blue-200", else: "bg-white border-gray-200 hover:shadow")
                      ]}
                      phx-click={JS.patch(~p"/app/members/#{@person_id}?context=#{membership.ou_id}")}
                    >
                      <div class="flex justify-between items-start">
                        <div class="flex flex-col">
                          <span class="font-semibold text-gray-900">{membership.ou.ou_name}</span>
                          <.ou_id_badge id={membership.ou_id} size="sm" class="mt-1" />
                        </div>
                        <.membership_status_badge status={membership.membership_status} />
                      </div>
                      <div class="flex justify-between items-center text-sm mt-2 border-t pt-3 border-gray-100">
                        <div class="flex items-center gap-2 text-gray-500">
                          <i class="fa-solid fa-calendar-day"></i>
                          <span>Desde {Timex.lformat!(membership.created_at, "{relative}", "es", :relative)}</span>
                        </div>
                        <.membership_rank_badge rank={membership.membership_rank} />
                      </div>
                    </div>
                  <% end %>
                <% end %>
              </div>

            <% "roles" -> %>
              <div class="space-y-4">
                <%= if context.roles == [] do %>
                  <div class="text-center py-8">
                    <p class="text-gray-500">No tiene roles asignados en esta unidad.</p>
                  </div>
                <% else %>
                  <div class="space-y-3">
                    <%= for role <- context.roles do %>
                      <div class="bg-white flex items-center justify-between p-4 border border-gray-200 rounded-xl shadow-sm">
                        <div>
                          <p class="font-medium text-gray-900">{role.role_name}</p>
                          <p class="text-xs text-gray-500 mt-1">{role.role_description}</p>
                        </div>
                      </div>
                    <% end %>
                  </div>
                <% end %>
              </div>

            <% "proposals" -> %>
              <div class="space-y-4">
                <%= if context.proposals == [] do %>
                  <div class="text-center py-8">
                    <p class="text-gray-500">No tiene propuestas en esta unidad.</p>
                  </div>
                <% else %>
                  <%= for proposal <- context.proposals do %>
                    <div class="bg-white p-4 rounded-xl border border-gray-200 shadow-sm hover:shadow transition cursor-pointer" phx-click={JS.patch(~p"/app/proposals/#{proposal.proposal_id}?context=#{@app_context.current_ou_id}")}>
                      <div class="flex justify-between items-start">
                        <h4 class="font-medium text-gray-900 line-clamp-1">{proposal.proposal_title}</h4>
                      </div>
                      <div class="flex gap-2 mt-2 items-center flex-wrap">
                        <.power_id_badge id={proposal.proposal_power_id} size="sm" />
                        <span class="text-xs text-gray-400">&bull;</span>
                        <span class="text-xs text-gray-500">{Timex.lformat!(proposal.created_at, "{relative}", "es", :relative)}</span>
                      </div>
                    </div>
                  <% end %>
                <% end %>
              </div>
          <% end %>
        </div>
      </.async_result>
    </div>
    """
  end
end
