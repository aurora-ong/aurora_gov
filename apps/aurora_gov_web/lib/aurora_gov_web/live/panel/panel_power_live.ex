defmodule PowerPanelComponent do
  # In Phoenix apps, the line is typically: use MyAppWeb, :live_component
  use Phoenix.LiveComponent

  # @impl true
  # def mount(socket) do
  #   socket =
  #     socket
  #     |> assign(:filter, "all")

  #   {:ok, socket}
  # end

  # @impl true
  # def update(assigns, socket) do
  #   socket =
  #     socket
  #     |> assign(:context, assigns.context)
  #     |> assign(
  #       :members,
  #       AuroraGov.Projector.Membership.get_all_membership_by_uo(assigns.context)
  #     )

  #   {:ok, socket}
  # end

  @impl true
  def render(assigns) do
    ~H"""
    <section class="card w-4/6 flex flex-col h-fit">
      <h2 class="text-2xl font-bold mb-6">Tabla de consensos</h2>

      <div class="grid grid-cols-2 gap-4">
        <div class="border px-5 py-5 rounded-lg">
          <div class="flex justify-between items-start">
            <div>
              <h3 class="text-lg font-semibold">Crear nueva unidad</h3>

              <p class="text-sm text-gray-600">
                Permite formalizar nuevas unidades organizativas dentro del árbol organizacional.
              </p>
            </div>

            <button class="text-blue-600 text-sm hover:underline" onclick="openModal('crear-unidad')">
              Actualizar mi sensibilidad
            </button>
          </div>

          <div class="mt-3">
            <label class="text-sm text-gray-500">
              Requiere <strong>45%</strong> de aprobación colectiva
            </label>

            <div class="w-full bg-gray-200 rounded-full h-2 mt-1">
              <div class="bg-blue-600 h-2 rounded-full" style="width: 45%;"></div>
            </div>

            <p class="text-xs text-gray-500 mt-2 flex flex-row items-center">
              <i class="fa-solid fa-hand mr-2" />Usado 2 veces en los últimos 7 días
            </p>
          </div>
        </div>

        <div class="border px-5 py-5 rounded-lg">
          <div class="flex justify-between items-start">
            <div>
              <h3 class="text-lg font-semibold">Iniciar membresía</h3>

              <p class="text-sm text-gray-600">
                Permite iniciar la membresía de una persona en una unidad organizacional.
              </p>
            </div>

            <button class="text-blue-600 text-sm hover:underline" onclick="openModal('crear-unidad')">
              Actualizar mi sensibilidad
            </button>
          </div>

          <div class="mt-5">
            <label class="text-sm text-gray-500">
              Requiere <strong>85%</strong> de aprobación colectiva
            </label>

            <div class="w-full bg-gray-200 rounded-full h-2 mt-1">
              <div class="bg-red-600 h-2 rounded-full" style="width: 85%;"></div>
            </div>

            <p class="text-xs text-gray-500 mt-2 flex flex-row items-center">
              <i class="fa-solid fa-hand mr-2" />Usado 0 veces en los últimos 7 días
            </p>
          </div>
        </div>
      </div>
    </section>
    """
  end

  @impl true
  def handle_event("update_filter", %{"filter" => filter}, socket) do
    IO.inspect(filter, label: "QQ")

    {:noreply, assign(socket, filter: filter)}
  end

  def handle_info(msg, socket) do
    IO.inspect(msg, label: "Actualizando PUBSUB Panel Members")
    {:noreply, socket}
  end
end
