defmodule AuroraGovWeb.Live.Panel.Home do
  # In Phoenix apps, the line is typically: use MyAppWeb, :live_component
  use Phoenix.LiveComponent

  def update(assigns, socket) do
    socket =
      socket
      |> assign(:context, assigns.context)
      |> assign(:page_title, "Inicio")
      |> assign(:ou, AuroraGov.Context.OUContext.get_ou_by_id(assigns.context))

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="w-full h-full flex flex-nowrap">
      <div class="flex flex-col items-center justify-center py-10 bg-gradient-to-r from-blue-100 to-white rounded-lg shadow-lg mb-6 gap-3 h-full w-2/3">
        <h1 class="text-4xl font-bold mb-2 flex items-center gap-2">
          <span class="ml-2 items-center gap-1 block">
            {@ou.ou_name}
          </span>
        </h1>

        <div class="max-w-2xl bg-white bg-opacity-80 rounded p-6 shadow">
          <h3 class="text-2xl font-semibold text-blue-700 mb-2">Descripción</h3>

          <p class="text-gray-800 text-base">
            {@ou.ou_description}
          </p>
        </div>

        <div class="max-w-2xl bg-white bg-opacity-80 rounded p-6 shadow">
          <h3 class="text-2xl font-semibold text-blue-700 mb-2">Objetivo</h3>

          <p class="text-gray-800 text-base">
            {@ou.ou_goal}
          </p>
        </div>

        <div class="max-w-2xl w-full bg-white bg-opacity-80 rounded p-6 shadow">
          <h3 class="text-2xl font-semibold text-blue-700 mb-2">
            Fundada el
            <span class="font-semibold">{@ou.created_at |> Calendar.strftime("%d/%m/%Y")}</span>
          </h3>
        </div>
      </div>
      <div class="w-1/3">

      <div class="bg-white bg-opacity-80 rounded shadow p-10">
        <h3 class="text-2xl font-semibold text-blue-700 mb-4">Última actividad</h3>

        <div class="flex flex-col gap-3">
          <%= for activity <- [
            %{title: "Se añadió nueva unidad", detail: "Unidad: Desarrollo de Producto", time: "Hoy - 09:24"},
            %{title: "Se añadió nuevo miembro", detail: "Usuario: María Pérez", time: "Ayer - 16:02"},
            %{title: "Se actualizó el objetivo", detail: "Objetivo actualizado por admin", time: "Hace 3 días - 11:45"},
            %{title: "Se modificó la descripción", detail: "Descripción ajustada", time: "Hace 1 semana - 08:10"}
          ] do %>
            <div class="bg-white rounded shadow-sm p-3 border border-gray-200">
              <div class="flex items-start justify-between gap-2">
                <div>
                  <div class="text-sm text-gray-600"><%= activity.time %></div>
                  <div class="font-medium text-gray-800"><%= activity.title %></div>
                  <div class="text-sm text-gray-600"><%= activity.detail %></div>
                </div>
                <div class="text-blue-500 text-xs font-semibold px-2 py-1 border border-blue-100 rounded">Nuevo</div>
              </div>
            </div>
          <% end %>
        </div>
      </div>

      </div>
    </div>
    """
  end
end
