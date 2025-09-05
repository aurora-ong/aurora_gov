defmodule AuroraGovWeb.Live.Power.SensibilityUpdate do
  alias AuroraGov.Context.PowerContext
  alias AuroraGov.Context.OUContext
  use AuroraGovWeb, :live_component
  alias Phoenix.LiveView.AsyncResult

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

  @impl true
  def mount(socket) do
    IO.inspect(socket.assigns)

    socket =
      socket
      |> assign(:power_update_context, AsyncResult.loading())

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(:context, assigns.context)
      |> assign(:power_id, assigns.power_id)
      |> assign(
        form:
          to_form(
            AuroraGov.Command.UpdatePower.new(),
            as: "power_update_form"
          )
      )
      |> start_async(:load_data, fn ->
        load_data(assigns.context, "000@test.com", assigns.power_id)
      end)

    {:ok, socket}
  end

  defp load_data(ou_id, person_id, power_id) do
    IO.inspect("Cargando #{ou_id}, #{person_id}, #{power_id}")

    tasks = [
      Task.async(fn -> PowerContext.get_power(ou_id, person_id, power_id) end),
      Task.async(fn -> PowerContext.get_ou_power(ou_id, power_id) end),
      Task.async(fn -> OUContext.get_ou_by_id(ou_id) end),
      Task.async(fn -> PowerContext.get_power_metadata(power_id) end)
    ]

    Task.await_many(tasks)
  end

  @impl true
  def handle_async(
        :load_data,
        {:ok, [result_power, result_ou_power, result_ou, result_power_metadata] = r},
        socket
      ) do
    IO.inspect(r)

    socket =
      socket
      |> assign(
        :power_update_context,
        AsyncResult.ok(%{
          ou: %{
            ou_id: result_ou.ou_id,
            ou_name: result_ou.ou_name
          },
          power: %{
            power_id: result_power_metadata.id,
            power_name: result_power_metadata.name,
            power_description: result_power_metadata.description
          },
          last_updated: result_power && Map.get(result_power, :updated_at),
          collective_value:
            case result_ou_power && result_ou_power.power_average do
              %Decimal{} = dec -> Decimal.to_integer(dec)
              _ -> "-"
            end
        })
      )
      |> then(fn socket ->
        if result_power != nil do
          assign(socket,
            form:
              to_form(
                AuroraGov.Command.UpdatePower.new(%{power_value: result_power.power_value}),
                as: "power_update_form"
              )
          )
        else
          socket
        end
      end)

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto my-auto w-max-lg flex flex-col justify-center items-start">
      <h2 class="text-2xl font-semibold flex items-center gap-2">
        <i class="fa-solid fa-hand text-2xl"></i> Actualizar postura
      </h2>

      <.async_result :let={power_context} assign={@power_update_context}>
        <:loading>
          <.loading_spinner />
        </:loading>

        <:failed :let={_failure}>error loading</:failed>

        <.simple_form
          for={@form}
          id="power_update_form"
          phx-submit="update"
          phx-change="validate"
          phx-target={@myself}
          class="w-full"
        >
          <% current = @form[:power_value].value || 50 %>

    <!-- Header -->

          <div class="mt-5 grid grid-cols-1 sm:grid-cols-12 gap-3 text-sm">

              <!-- Card: Unidad organizativa -->
            <div class="sm:col-span-6 flex items-center gap-3 rounded-xl border bg-white p-3 shadow-sm">
              <div class="flex h-10 w-10 items-center justify-center rounded-lg bg-black/90">
                <i class="fa-solid fa-sitemap rotate-180 text-white"></i>
              </div>

              <div class="min-w-0 flex-1">
                <div class="text-gray-900 font-medium truncate" title={power_context.ou.ou_name}>
                  {power_context.ou.ou_name}
                </div>

                <div class="mt-1">
                  <span class="inline-flex items-center rounded px-2 py-0.5 bg-black text-white text-xs font-semibold">
                    {power_context.ou.ou_id}
                  </span>
                </div>
              </div>
            </div>

    <!-- Card: Poder -->
            <div class="sm:col-span-6 flex items-center gap-3 rounded-xl border bg-white p-3 shadow-sm">
              <div class="flex h-10 w-10 items-center justify-center rounded-lg bg-aurora_orange/10">
                <i class="fa-solid fa-bolt text-aurora_orange"></i>
              </div>

              <div class="min-w-0 flex-1">
                <div class="text-gray-900 font-medium truncate" title={power_context.power.power_name}>
                  {power_context.power.power_name}
                </div>

                <div class="mt-1">
                  <span class="inline-flex items-center rounded px-2 py-0.5 bg-aurora_orange/10 text-aurora_orange text-xs font-semibold">
                    {power_context.power.power_id}
                  </span>
                </div>
              </div>
            </div>



    <!-- Card: Descripción del poder (ocupa 12 columnas) -->
            <div class="sm:col-span-12 rounded-xl border bg-white p-4 sm:px-3 sm:py-3 shadow-sm">
              <div class="flex items-center gap-2">
                <i class="fa-solid fa-circle-info text-blue-600"></i>
                <p class="text-sm leading-relaxed text-gray-600">
                  {power_context.power.power_description || power_context.power.description ||
                    "Sin descripción disponible."}
                </p>
              </div>
            </div>
          </div>

    <!-- Tarjeta de métricas -->
          <div class="mt-6 rounded-2xl border shadow-sm p-6">
            <div class="grid grid-cols-2 divide-x">
              <div class="text-center">
                <div class="text-6xl font-semibold leading-none">{current}</div>

                <div class="mt-2 text-sm text-gray-500">Mi postura actual</div>
              </div>

              <div class="text-center">
                <div class="text-6xl font-semibold text-aurora_orange leading-none">
                  {power_context.collective_value}
                </div>

                <div class="mt-2 text-sm text-gray-500">Postura colectiva</div>
              </div>
            </div>
          </div>

    <!-- Barras de referencia + slider -->
          <div class="mt-6">
            <.input
              field={@form[:power_value]}
              type="range"
              min="0"
              max="100"
              step="5"
              class="accent-aurora_orange"

            />

    <!-- leyenda dinámica -->

            <% {label, icon, label_class, description} =
              posture_meta(current) %>
            <div class="mt-3 flex items-center gap-2 text-sm">
              <i class={"fa-solid #{icon} #{label_class}"}></i>
              <span class={"font-semibold #{label_class}"}>{label}</span>
              <span class="text-gray-500">
                {description}
              </span>
            </div>
          </div>

    <!-- Última actualización -->

          <.button phx-disable-with="..." class="w-full">
            Actualizar
          </.button>

          <div class="mt-1 text-xs text-gray-500 flex items-center gap-2">
            <i class="fa-solid fa-calendar-days"></i>
            <span>
              {if !power_context.last_updated do
                "Aún no has actualizado tu postura."
              else
                "Actualizado " <>
                  Timex.lformat!(power_context.last_updated, "{relative}", "es", :relative)
              end}
            </span>
          </div>
        </.simple_form>
      </.async_result>
    </div>
    """
  end

  @impl true
  def handle_event(
        "validate",
        %{"power_update_form" => params},
        socket
      ) do
    changeset =
      params
      |> AuroraGov.Command.UpdatePower.new()
      |> Map.put(:action, :validate)

    IO.inspect(changeset)

    socket =
      socket
      |> assign(
        form:
          to_form(
            changeset,
            as: "power_update_form"
          )
      )

    {:noreply, socket}
  end

  @impl true
  def handle_event("update", %{"power_update_form" => params}, socket) do
    update_params =
      params
      |> Map.put("person_id", "000@test.com")
      |> Map.put("ou_id", socket.assigns.context)
      |> Map.put("power_id", socket.assigns.power_id)

    socket =
      case AuroraGov.Context.PowerContext.update_person_power!(update_params) do
        {:ok, _result} ->
          send_update(AuroraGovWeb.Live.Panel.Power,
            id: "panel-power",
            close_modal: "update_power_modal"
          )

          socket
          |> put_flash(:info, "Actualizado")
          |> push_event("close_modal", %{modal: "power_update_modal"})

        {:error, changeset} ->
          socket
          |> assign(
            form:
              to_form(
                changeset,
                as: "power_update_form"
              )
          )
          |> put_flash(:error, "No se pudo actualizar")
      end

    {:noreply, socket}
  end
end
