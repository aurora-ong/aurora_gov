defmodule AuroraGov.Web.Live.Panel.Side.LastActivity do
  use AuroraGov.Web, :live_component
  alias Phoenix.LiveView.AsyncResult
  require Logger

  defmodule Context do
    defstruct activity_list: nil
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
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> start_async(:load_context, fn -> load_context() end)

    {:ok, socket}
  end

  defp load_context() do
    :timer.sleep(250)

    %Context{
      activity_list: [
        %{
          title: "Se añadió nueva unidad",
          detail: "Unidad: Desarrollo de Producto",
          time: "Hoy - 09:24"
        },
        %{title: "Se añadió nuevo miembro", detail: "Usuario: María Pérez", time: "Ayer - 16:02"},
        %{
          title: "Se actualizó el objetivo",
          detail: "Objetivo actualizado por admin",
          time: "Hace 3 días - 11:45"
        },
        %{
          title: "Se modificó la descripción",
          detail: "Descripción ajustada",
          time: "Hace 1 semana - 08:10"
        }
      ]
    }
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
              {inspect(error)}
            </p>
          </div>
        </:failed>

          <h3 class="text-2xl font-semibold text-blue-700 mb-4">Última actividad</h3>

          <div class="flex flex-col gap-3">
            <%= for activity <- context.activity_list  do %>
              <div class="bg-white rounded shadow-sm p-3 border border-gray-200">
                <div class="flex items-start justify-between gap-2">
                  <div>
                    <div class="text-sm text-gray-600">{activity.time}</div>

                    <div class="font-medium text-gray-800">{activity.title}</div>

                    <div class="text-sm text-gray-600">{activity.detail}</div>
                  </div>

                  <div class="text-blue-500 text-xs font-semibold px-2 py-1 border border-blue-100 rounded">
                    Nuevo
                  </div>
                </div>
              </div>
            <% end %>
          </div>
      </.async_result>
    </div>
    """
  end
end
