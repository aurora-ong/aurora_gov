defmodule AuroraGov.Web.Live.Panel.Side.PowerDetail do
  alias AuroraGov.Web.Live.Panel.AppView
  use AuroraGov.Web, :live_component
  alias Phoenix.LiveView.AsyncResult
  require Logger

  alias AuroraGov.Context.{
    PowerContext,
    OUContext,
    PowerDelegationContext,
    GovPowerContext,
    OuPowerContext,
    MembershipContext
  }

  defmodule Context do
    defstruct [
      :power_info,
      :ou_power,
      :sensitivities,
      :sub_units,
      :user_delegations,
      :sub_unit_memberships,
      :person_id,
      :ou_id,
      :power_id,
      :user_power,
      :membership
    ]
  end

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:context, AsyncResult.loading())
      |> assign(:active_tab, "sensitivities")

    {:ok, socket}
  end

  @impl true
  def update(%{update: {:power_updated, %{power_id: power_id}}}, socket) do
    if power_id == socket.assigns.power_id do
      refresh_context(socket)
    else
      {:ok, socket}
    end
  end

  @impl true
  def update(%{update: {:power_delegation_activated, %{power_id: power_id}}}, socket) do
    if power_id == socket.assigns.power_id do
      refresh_context(socket)
    else
      {:ok, socket}
    end
  end

  @impl true
  def update(%{update: {:power_delegation_deactivated, %{power_id: power_id}}}, socket) do
    if power_id == socket.assigns.power_id do
      refresh_context(socket)
    else
      {:ok, socket}
    end
  end

  @impl true
  def update(assigns, socket) do
    power_id = assigns[:power_id]
    ou_id = assigns.app_context.current_ou_id
    person_id = assigns.app_context.current_person && assigns.app_context.current_person.person_id

    socket =
      socket
      |> assign(assigns)
      |> assign(:power_id, power_id)
      |> start_async(:load_context, fn -> load_context(ou_id, power_id, person_id) end)

    {:ok, socket}
  end

  defp load_context(ou_id, power_id, person_id) do
    power_info = GovPowerContext.get_gov_power!(power_id)
    ou_power = OuPowerContext.get_ou_power(ou_id, power_id)
    sensitivities = PowerContext.list_power_sensitivities(ou_id, power_id)
    sub_units = OUContext.list_ou_childs(ou_id)
    user_power = person_id && PowerContext.get_power(ou_id, person_id, power_id)
    membership = person_id && MembershipContext.get_membership(ou_id, person_id)

    {user_delegations, sub_unit_memberships} =
      if person_id do
        Enum.reduce(sub_units, {%{}, %{}}, fn sub_ou, {delegations, memberships} ->
          delegation = PowerDelegationContext.get_user_delegation(person_id, power_id, sub_ou.ou_id)
          membership_in_sub = MembershipContext.get_membership(sub_ou.ou_id, person_id)

          {
            Map.put(delegations, sub_ou.ou_id, delegation != nil),
            Map.put(memberships, sub_ou.ou_id, membership_in_sub != nil)
          }
        end)
      else
        {%{}, %{}}
      end

    %Context{
      power_info: power_info,
      ou_power: ou_power,
      sensitivities: sensitivities,
      sub_units: sub_units,
      user_delegations: user_delegations,
      sub_unit_memberships: sub_unit_memberships,
      person_id: person_id,
      ou_id: ou_id,
      power_id: power_id,
      user_power: user_power,
      membership: membership
    }
  end

  defp refresh_context(socket) do
    ou_id = socket.assigns.app_context.current_ou_id
    power_id = socket.assigns.power_id
    person_id = socket.assigns.app_context.current_person && socket.assigns.app_context.current_person.person_id

    socket =
      socket
      |> start_async(:load_context, fn -> load_context(ou_id, power_id, person_id) end)

    {:ok, socket}
  end

  @impl true
  def handle_async(:load_context, {:ok, %Context{} = context}, socket) do
    {:noreply, assign(socket, :context, AsyncResult.ok(context))}
  end

  @impl true
  def handle_event("select_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, :active_tab, tab)}
  end

  @impl true
  def handle_event("open_sensitivity_modal", _, socket) do
    app_modal = %AppView{
      view_id: "power-update_power-#{socket.assigns.power_id}",
      view_module: AuroraGov.Web.Live.Power.SensibilityUpdate,
      view_options: %{
        modal_size: "double_large"
      },
      view_params: %{
        power_id: socket.assigns.power_id
      }
    }

    send(self(), {:open, :app_modal, app_modal})
    {:noreply, socket}
  end

  @impl true
  def handle_event("toggle_delegation", %{"sub_ou_id" => sub_ou_id, "active" => active}, socket) do
    person_id = socket.assigns.app_context.current_person.person_id
    power_id = socket.assigns.power_id

    command =
      if active == "true" do
        %AuroraGov.Command.DeactivatePowerDelegation{
          person_id: person_id,
          ou_id: sub_ou_id,
          power_id: power_id
        }
      else
        %AuroraGov.Command.ActivatePowerDelegation{
          person_id: person_id,
          ou_id: sub_ou_id,
          power_id: power_id
        }
      end

    case AuroraGov.dispatch(command, consistency: :strong) do
      :ok ->
        {:noreply, socket}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Error al procesar delegación")}
    end
  end

  @impl true
  def handle_event("toggle_delegation_notification", %{"sub_ou_id" => _sub_ou_id}, socket) do
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col h-full">
      <.async_result :let={context} assign={@context}>
        <:loading><.loading_spinner size="double_large" /></:loading>

        <div class="mb-4">
          <div class="flex items-center gap-3 mb-2">
            <div class="p-2 bg-blue-50 text-blue-600 rounded-lg">
              <i class="fa-solid fa-bolt text-xl"></i>
            </div>
            <div>
              <h2 class="text-xl font-bold text-gray-900 m-0">{context.power_info.name}</h2>
              <p class="text-sm text-gray-500">{context.power_info.description}</p>
            </div>
          </div>

          <div class="mt-4 grid grid-cols-2 gap-3">
            <div class="p-4 bg-blue-600 rounded-2xl text-white shadow-lg shadow-blue-100 flex flex-col justify-between h-28">
              <div class="flex justify-between items-start">
                <div class="text-[10px] font-bold uppercase tracking-widest opacity-80">Quorum Colectivo</div>
                <i class="fa-solid fa-users text-sm opacity-60"></i>
              </div>
              <div class="text-3xl font-black">
                {if context.ou_power, do: Decimal.round(context.ou_power.power_average, 1), else: "0"}%
              </div>
            </div>

            <%= if context.person_id do %>
              <%= if is_nil(context.membership) or context.membership.membership_rank == "junior" do %>
                <div class="p-4 bg-orange-50 rounded-2xl border border-orange-100 flex flex-col justify-center items-center text-center gap-1 h-28">
                  <i class="fa-solid fa-lock text-orange-400 text-lg"></i>
                  <span class="text-[10px] font-bold text-orange-800 uppercase tracking-tighter leading-tight">Postura Restringida</span>
                </div>
              <% else %>
                <div
                  phx-click="open_sensitivity_modal"
                  phx-target={@myself}
                  class="p-4 bg-white rounded-2xl border border-gray-100 shadow-lg shadow-gray-100 flex flex-col justify-between h-28 cursor-pointer hover:border-blue-400 transition-all group"
                >
                  <div class="flex justify-between items-start">
                    <div class="text-[10px] font-bold uppercase tracking-widest text-gray-400 group-hover:text-blue-600 transition-colors">Mi Postura</div>
                    <i class="fa-solid fa-pen-to-square text-sm text-gray-300 group-hover:text-blue-500"></i>
                  </div>
                  <div class="flex items-baseline gap-1">
                    <span class="text-3xl font-black text-gray-900 group-hover:text-blue-700 transition-colors">
                      {(context.user_power && context.user_power.power_value) || "-"}%
                    </span>
                  </div>
                  <div class="text-[8px] text-gray-400 font-medium truncate">
                    <%= if context.user_power && context.user_power.updated_at do %>
                      Actualizado {Timex.lformat!(context.user_power.updated_at, "{relative}", "es", :relative)}
                    <% else %>
                      Click para actualizar
                    <% end %>
                  </div>
                </div>
              <% end %>
            <% end %>
          </div>
        </div>

        <div class="flex border-b border-gray-200 mb-4 mt-6">
          <button
            phx-click="select_tab"
            phx-value-tab="sensitivities"
            phx-target={@myself}
            class={"px-4 py-2 text-sm font-medium border-b-2 transition-colors #{if @active_tab == "sensitivities", do: "border-blue-600 text-blue-600", else: "border-transparent text-gray-500 hover:text-gray-700"}"}
          >
            Posturas
             <.badge
            size="xs"
            class="border border-gray-300 rounded-lg p-2 py-1 cursor-pointer h-fit ml-2"
          >
          {Enum.count(context.sensitivities)}
          </.badge>

          </button>
          <button
            phx-click="select_tab"
            phx-value-tab="delegation"
            phx-target={@myself}
            class={"px-4 py-2 text-sm font-medium border-b-2 transition-colors #{if @active_tab == "delegation", do: "border-blue-600 text-blue-600", else: "border-transparent text-gray-500 hover:text-gray-700"}"}
          >
            Delegación
            <.badge
              size="xs"
              class="border border-gray-300 rounded-lg p-2 py-1 cursor-pointer h-fit ml-2"
            >
              {Enum.count(context.user_delegations, fn {_id, is_active} -> is_active end)}
            </.badge>
          </button>
        </div>

        <div class="flex-1 overflow-y-auto pr-2">
          <%= if @active_tab == "sensitivities" do %>
            <div class="space-y-4">
              <div :if={Enum.empty?(context.sensitivities)} class="text-center py-8 text-gray-500">
                No hay posturas registradas para este poder.
              </div>

              <%= for sensitivity <- context.sensitivities do %>
                <div class="p-3 border rounded-lg bg-gray-50 flex items-center justify-between">
                  <div class="flex items-center gap-3">
                    <.avatar
                      size="sm"
                      rounded="full"
                      color="silver"
                    >
                      {String.at(sensitivity.person.person_name, 0)}
                    </.avatar>
                    <div>
                      <div class="text-sm font-bold text-gray-900">
                        {sensitivity.person.person_name}
                      </div>
                      <%!-- <div class="text-xs text-gray-500">
                        Postura: {elem(posture_meta(to_integer(sensitivity.power_value)), 0)}
                      </div> --%>
                    </div>
                  </div>
                  <div class={"text-sm font-bold #{elem(posture_meta(to_integer(sensitivity.power_value)), 2)}"}>
                    {to_integer(sensitivity.power_value)}%
                  </div>
                </div>
              <% end %>
            </div>
          <% else %>
            <div class="space-y-6">
              <div class="bg-blue-50 p-4 rounded-xl border border-blue-100 mb-4">
                <div class="flex gap-3">
                  <i class="fa-solid fa-circle-info text-blue-500 mt-1"></i>
                  <p class="text-xs text-blue-800 leading-relaxed">
                    Delega tu poder en unidades que confíes. Estas unidades podrán utilizar tu voto en propuestas que utilicen en este poder.
                  </p>
                </div>
              </div>

              <%= if is_nil(context.membership) or context.membership.membership_rank == "junior" do %>
                 <div class="p-6 bg-orange-50 rounded-2xl border border-orange-100 flex flex-col items-center text-center gap-3">
                   <div class="h-12 w-12 bg-orange-100 text-orange-600 rounded-full flex items-center justify-center">
                     <i class="fa-solid fa-lock text-xl"></i>
                   </div>
                   <div>
                     <h4 class="font-bold text-orange-900">Acceso Restringido</h4>
                     <p class="text-xs text-orange-800 leading-relaxed mt-1">
                       Debes tener un rango mayor a <b>junior</b> para delegar tu poder.
                     </p>
                   </div>
                 </div>
              <% else %>
                <div class="space-y-4">
                  <%!-- <h3 class="text-[10px] font-black text-gray-400 uppercase tracking-[0.2em]">Subunidades directas</h3> --%>
                  <div :if={Enum.empty?(context.sub_units)} class="text-center py-8 text-gray-500">
                    No hay subunidades directas registradas.
                  </div>

                  <%= for sub_ou <- context.sub_units do %>
                    <% is_member = Map.get(context.sub_unit_memberships, sub_ou.ou_id, false) %>
                    <div class={"p-4 border rounded-2xl bg-white shadow-sm space-y-4 #{if is_member, do: "opacity-75 bg-gray-50/50"}"}>
                      <div class="flex items-center justify-between">
                        <div class="flex items-center gap-3">
                          <div class="w-10 h-10 rounded-xl bg-gray-100 flex items-center justify-center text-gray-500">
                             <i class="fa-solid fa-sitemap"></i>
                          </div>
                          <div>
                            <div class="font-bold text-gray-900">{sub_ou.ou_name}</div>
                            <div class="text-[10px] text-gray-400 font-mono tracking-tighter">{sub_ou.ou_id}</div>
                          </div>
                        </div>

                        <%= if is_member do %>
                          <div class="flex flex-col items-end gap-1">
                            <div class="bg-gray-100 text-gray-500 px-3 py-1.5 rounded-lg text-[10px] font-bold uppercase tracking-wider flex items-center gap-1.5 border border-gray-200">
                              <i class="fa-solid fa-user-check text-xs"></i> Miembro
                            </div>
                          </div>
                        <% else %>
                          <button
                            phx-click="toggle_delegation"
                            phx-value-sub_ou_id={sub_ou.ou_id}
                            phx-value-active={"#{Map.get(context.user_delegations, sub_ou.ou_id, false)}"}
                            phx-target={@myself}
                            class={"px-4 py-2 rounded-xl text-xs font-black uppercase tracking-widest transition-all #{if Map.get(context.user_delegations, sub_ou.ou_id, false), do: "bg-red-50 text-red-600 hover:bg-red-100", else: "bg-blue-600 text-white hover:bg-blue-700 shadow-md shadow-blue-200"}"}
                          >
                            <%= if Map.get(context.user_delegations, sub_ou.ou_id, false) do %>
                              Desactivar
                            <% else %>
                              Activar
                            <% end %>
                          </button>
                        <% end %>
                      </div>

                      <div :if={!is_member && Map.get(context.user_delegations, sub_ou.ou_id, false)} class="pt-4 border-t border-gray-50 flex items-center justify-between">
                        <div class="flex items-center gap-2">
                           <i class="fa-solid fa-bell text-blue-600 text-xs"></i>
                           <span class="text-xs text-gray-600">Notificar uso</span>
                        </div>

                        <label class="relative inline-flex items-center cursor-pointer">
                          <input
                            type="checkbox"
                            class="sr-only peer"
                            checked={true}
                            phx-click="toggle_delegation_notification"
                            phx-value-sub_ou_id={sub_ou.ou_id}
                            phx-target={@myself}
                          >
                          <div class="w-9 h-5 bg-gray-200 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full rtl:peer-checked:after:-translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-0.5 after:start-0.5 after:bg-white after:border-gray-300 after:border after:rounded-full after:h-4 after:w-4 after:transition-all peer-checked:bg-blue-600"></div>
                        </label>
                      </div>
                    </div>
                  <% end %>
                </div>
              <% end %>
            </div>
          <% end %>
        </div>
      </.async_result>
    </div>
    """
  end

  defp posture_meta(v) when is_integer(v) do
    cond do
      v < 33 ->
        {"Postura ágil", "fa-bolt", "text-emerald-600",
         "Las decisiones que involucren este poder se aprobarán más rapidamente pues requerirán menor cantidad de votos positivos."}

      v < 75 ->
        {"Postura flexible", "fa-wave-square", "text-aurora_orange",
         "Las decisiones que involucren este poder requerirán cierta cantidad de votos positivos."}

      true ->
        {"Postura cautelosa", "fa-lock", "text-red-500",
         "Las decisiones que involucren este poder requerirán mayor cantidad de votos positivos."}
    end
  end

  defp to_integer(%Decimal{} = d), do: Decimal.to_integer(d)
  defp to_integer(n) when is_integer(n), do: n
  defp to_integer(n) when is_binary(n), do: String.to_integer(n)
  defp to_integer(_), do: 0
end
