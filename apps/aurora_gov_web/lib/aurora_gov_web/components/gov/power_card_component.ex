defmodule AuroraGov.Web.Components.Power.PowerCardComponent do
  alias AuroraGov.Web.Live.Panel.AppView
  use AuroraGov.Web, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div
      class="border px-5 py-5 rounded-lg flex flex-col justify-between cursor-pointer hover:border-blue-400 transition-all hover:shadow-md"
      phx-click="open_power_detail"
      phx-target={@myself}
      phx-value-power_id={@power_id}
    >
      <div class="flex justify-between items-start">
        <div>
          <h3 class="text-lg font-semibold text-gray-900">{(@power_info && @power_info.name) || @power_id}</h3>
          <p class="text-xs text-gray-500 line-clamp-2 mt-1">{(@power_info && @power_info.description) || ""}</p>
        </div>
      </div>

      <%!-- Caso: Tiene Power --%>
      <div :if={@ou_power != nil} class="mt-3">
        <div class="grid grid-cols-2 gap-2 mt-4 text-white">
          <div
            class={"select-none p-2.5 rounded-2xl shadow-md transition-all active:scale-95 #{quorum_color(to_percent(@ou_power.power_average))}"}
            title="Quórum"
          >
            <div class="flex justify-between items-center text-[10px] font-bold uppercase tracking-wider opacity-90">
              Quórum <i class="fa-solid fa-users"></i>
            </div>
            <div class="text-2xl font-black leading-none mt-1.5">
              {to_percent(@ou_power.power_average)}<span class="text-sm font-medium ml-0.5">%</span>
            </div>
          </div>

          <div
            class={"select-none p-2.5 rounded-2xl shadow-md transition-all active:scale-95 #{participacion_color(to_percent((@ou_power.power_count/@ou_vote_membership_count)*100))}"}
            title="Participación"
          >
            <div class="flex justify-between items-center text-[10px] font-bold uppercase tracking-wider opacity-90">
              Participación <i class="fa-solid fa-check-to-slot"></i>
            </div>
            <div class="text-2xl font-black leading-none mt-1.5">
              {to_percent(@ou_power.power_count / @ou_vote_membership_count * 100)}<span class="text-sm font-medium ml-0.5">%</span>
            </div>
          </div>

        </div>
      </div>

      <%!-- Caso: NO Tiene Power --%>
      <div :if={@ou_power == nil} class="mt-3">
        <div class="grid grid-cols-3 gap-2 mt-4 text-white opacity-60">
          <div
            class="select-none p-2.5 rounded-2xl shadow-md transition-all active:scale-95 bg-neutral-500 text-white"
            title="Quórum"
          >
            <div class="flex justify-between items-center text-[10px] font-bold uppercase tracking-wider opacity-90">
              Quórum <i class="fa-solid fa-users"></i>
            </div>
            <div class="text-2xl font-black leading-none mt-1.5">
              0<span class="text-sm font-medium ml-0.5">%</span>
            </div>
          </div>

          <div
            class="select-none p-2.5 rounded-2xl shadow-md transition-all active:scale-95 bg-neutral-500 text-white"
            title="Participación"
          >
            <div class="flex justify-between items-center text-[10px] font-bold uppercase tracking-wider opacity-90">
              Participación <i class="fa-solid fa-check-to-slot"></i>
            </div>
            <div class="text-2xl font-black leading-none mt-1.5">
              0<span class="text-sm font-medium ml-0.5">%</span>
            </div>
          </div>

        </div>
      </div>
    </div>
    """
  end

  # Helpers

  defp to_percent(nil), do: 0
  defp to_percent(%Decimal{} = d), do: Decimal.to_float(d)
  defp to_percent(n) when is_integer(n) or is_float(n), do: n

  defp quorum_color(value) do
    cond do
      value < 33 -> "bg-blue-100 text-blue-800"
      value > 66 -> "bg-red-100 text-red-800"
      true -> "bg-orange-100 text-orange-800"
    end
  end

  defp participacion_color(value) do
    cond do
      value > 66 -> "bg-green-100 text-green-800"
      value > 33 -> "bg-yellow-100 text-yellow-800"
      true -> "bg-red-100 text-red-800"
    end
  end

  defp delegation_color(value) do
    cond do
      value > 0 -> "bg-blue-600 text-white"
      true -> "bg-neutral-500 text-white"
    end
  end

  @impl true
  def handle_event("open_power_detail", %{"power_id" => power_id}, socket) do
    app_panel = %AppView{
      view_id: "power-detail-#{power_id}",
      view_module: AuroraGov.Web.Live.Panel.Side.PowerDetail,
      view_params: %{
        power_id: power_id
      }
    }

    send(self(), {:open, :app_side_panel, app_panel})

    {:noreply, socket}
  end

  @impl true
  def handle_event("update_power", %{"power_id" => power_id}, socket) do
    handle_event("open_power_detail", %{"power_id" => power_id}, socket)
  end

  @impl true
  def handle_event("update_power_delegation", %{"power_id" => power_id}, socket) do
    handle_event("open_power_detail", %{"power_id" => power_id}, socket)
  end
end
