defmodule AuroraGov.Web.Components.Power.PowerCardComponent do
  alias AuroraGov.Web.Live.Panel.AppView
  use AuroraGov.Web, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div class="border px-5 py-5 rounded-lg flex flex-col justify-between">
      <div class="flex justify-between items-start">
        <div>
          <h3 class="text-lg font-semibold">
            {(@power_info && @power_info[:name]) || @power_id}
          </h3>

          <p class="text-sm text-gray-600">
            {(@power_info && @power_info[:description]) || ""}
          </p>
        </div>

        <div :if={@show_actions && @app_context.current_person != nil} class="flex flex-row gap-1">
          <button
            phx-click="update_power"
            phx-target={@myself}
            phx-value-power_id={@power_id}
            class="justify-center items-center text-lg primary outlined px-3!"
          >
            <i class="fa-solid fa-hand-point-up text-sm"></i>
          </button>

          <button
            :if={false}
            phx-click="update_power"
            phx-value-power_id={@power_id}
            phx-target={@parent_target}
            class="justify-center items-center text-lg primary outlined px-3!"
          >
            <i class="fa-solid fa-eye text-sm"></i>
          </button>
        </div>
      </div>

      <div :if={@ou_power != nil} class="mt-3">
        <div class="flex flex-row">
          <label class="text-sm text-gray-500 grow">
            Requiere <strong>{to_percent(@ou_power.power_average)}%</strong> de aprobación colectiva
          </label>

          <span
            title="Cantidad de miembros que han manifestado su postura."
            class="text-sm flex flex-row items-center gap-1"
          >
            <%!-- {@ou_power.voters}/{@ou_power.members_total} --%> 10/10
            <i class="fa-solid fa-user-group text-sm"></i>
          </span>
        </div>

        <div class="w-full bg-gray-200 rounded-full h-2 mt-1">
          <div
            class={"#{get_progress_bar_color(to_percent(@ou_power.power_average))} h-2 rounded-full"}
            style={"width: #{to_percent(@ou_power.power_average)}%;"}
          >
          </div>
        </div>

        <p class="text-xs text-gray-500 mt-2 flex flex-row items-center">
          <%!-- <i class="fa-solid fa-hand mr-2" />Usado {@ou_power.power_use_7_days} veces en los últimos 7 días --%>
        </p>
      </div>

      <div :if={@ou_power == nil} class="mt-3">
        <div class="flex flex-row">
          <label class="text-sm text-gray-500 grow">
            Sin postura
          </label>

          <span class="text-sm flex flex-row items-center gap-1">
            0/12 <i class="fa-solid fa-user-group text-sm"></i>
          </span>
        </div>

        <div class="w-full bg-gray-200 rounded-full h-2 mt-1">
          <div class="bg-gray-600 h-2 rounded-full" style="width: 50%;"></div>
        </div>

        <p class="text-xs text-gray-500 mt-2 flex flex-row items-center">
          <%!-- placeholder de métricas --%>
        </p>
      </div>
    </div>
    """
  end

  # Helpers

  defp to_percent(nil), do: 0
  defp to_percent(%Decimal{} = d), do: Decimal.to_float(d)
  defp to_percent(n) when is_integer(n) or is_float(n), do: n

  defp get_progress_bar_color(power_consensus) do
    cond do
      power_consensus <= 33 -> "bg-blue-600"
      power_consensus >= 66 -> "bg-red-600"
      true -> "bg-aurora_orange"
    end
  end

  @impl true
  def handle_event("update_power", %{"power_id" => power_id}, socket) do
    app_modal = %AppView{
      view_id: "power-update_power-#{power_id}",
      view_module: AuroraGov.Web.Live.Power.SensibilityUpdate,
      view_options: %{
        modal_size: "double_large"
      },
      view_params: %{
        power_id: power_id
      }
    }

    send(self(), {:open, :app_modal, app_modal})

    {:noreply, socket}
  end
end
