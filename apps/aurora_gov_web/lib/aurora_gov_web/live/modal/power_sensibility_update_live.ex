defmodule AuroraGov.Web.Live.Power.SensibilityUpdate do
  alias AuroraGov.Context.{MembershipContext, PowerContext, GovPowerContext, OuPowerContext}
  alias AuroraGov.Context.OUContext
  use AuroraGov.Web, :live_component
  alias Phoenix.LiveView.AsyncResult

  defp posture_meta(v) when is_binary(v) do
    case Integer.parse(v) do
      {int, _} -> posture_meta(int)
      :error -> posture_meta(50)
    end
  end

  defp posture_meta(v) when is_integer(v) do
    cond do
      v < 33 ->
        {"Postura ágil", "fa-bolt", "text-emerald-600",
         "Las decisiones que involucren este poder se aprobarán más rápidamente pues requerirán menor cantidad de votos positivos."}

      v < 75 ->
        {"Postura flexible", "fa-wave-square", "text-aurora_orange",
         "Las decisiones que involucren este poder requerirán cierta cantidad de votos positivos."}

      true ->
        {"Postura cautelosa", "fa-lock", "text-red-500",
         "Las decisiones que involucren este poder requerirán mayor cantidad de votos positivos."}
    end
  end

  defp posture_meta(_), do: posture_meta(50)

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:page_title, "Actualizar Postura")
      |> assign(:power_update_context, AsyncResult.loading())

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    person_id = assigns.app_context.current_person && assigns.app_context.current_person.person_id
    ou_id = assigns.app_context.current_ou_id
    power_id = assigns.power_id

    socket =
      socket
      |> assign(assigns)
      |> assign(:id, assigns.id)
      |> assign(:app_context, assigns.app_context)
      |> assign(:power_id, power_id)
      |> assign(
        form:
          to_form(
            AuroraGov.Command.UpdatePower.new(%{
              "person_id" => person_id,
              "ou_id" => ou_id,
              "power_id" => power_id,
              "power_value" => 50
            }),
            as: "power_update_form"
          )
      )
      |> start_async(:load_data, fn ->
        load_data(ou_id, person_id, power_id)
      end)

    {:ok, socket}
  end

  defp load_data(ou_id, person_id, power_id) do
    IO.inspect("Cargando #{ou_id}, #{person_id}, #{power_id}")

    tasks = [
      Task.async(fn -> PowerContext.get_power(ou_id, person_id, power_id) end),
      Task.async(fn -> OuPowerContext.get_ou_power(ou_id, power_id) end),
      Task.async(fn -> OUContext.get_ou(ou_id) end),
      Task.async(fn -> GovPowerContext.get_gov_power!(power_id) end),
      Task.async(fn -> MembershipContext.get_membership(ou_id, person_id) end)
    ]

    Task.await_many(tasks)
  end

  @impl true
  def handle_async(
        :load_data,
        {:ok, [result_power, result_ou_power, result_ou, result_power_metadata, membership] = r},
        socket
      ) do
    IO.inspect(r)

    socket =
      cond do
        is_nil(membership) ->
          assign(
            socket,
            :power_update_context,
            AsyncResult.failed(socket.assigns.power_update_context, :no_membership)
          )

        membership.membership_rank == "junior" ->
          assign(
            socket,
            :power_update_context,
            AsyncResult.failed(socket.assigns.power_update_context, :insufficient_membership)
          )

        true ->
          socket
          |> assign(
            :power_update_context,
            build_power_context(result_power, result_ou_power, result_ou, result_power_metadata)
          )
          |> maybe_update_form(result_power)
      end

    {:noreply, socket}
  end

  defp build_power_context(result_power, result_ou_power, result_ou, result_power_metadata) do
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
      last_updated: result_power && result_power.updated_at,
      collective_value: calculate_collective_value(result_ou_power)
    })
  end

  defp calculate_collective_value(%{power_average: %Decimal{} = dec}),
    do: Decimal.round(dec, 1)

  defp calculate_collective_value(_), do: "-"

  defp maybe_update_form(socket, nil), do: socket

  defp maybe_update_form(socket, result_power) do
    person_id =
      socket.assigns.app_context.current_person &&
        socket.assigns.app_context.current_person.person_id

    ou_id = socket.assigns.app_context.current_ou_id
    power_id = socket.assigns.power_id

    assign(
      socket,
      :form,
      to_form(
        AuroraGov.Command.UpdatePower.new(%{
          "person_id" => person_id,
          "ou_id" => ou_id,
          "power_id" => power_id,
          "power_value" => result_power.power_value
        }),
        as: "power_update_form"
      )
    )
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id={@id}>
      <.modal
        id={"inner-#{@id}"}
        show
        title="Actualizar postura"
        title_icon="fa-solid fa-hand"
        size="double_large"
        on_cancel={JS.push("app_modal_close", value: %{modal: @id})}
      >
        <.async_result :let={power_context} assign={@power_update_context}>
          <:loading><.loading_spinner size="double_large" /></:loading>

          <:failed :let={error}>
            <div class="w-full flex flex-col items-center justify-center gap-4 p-6">
              <div class="text-4xl">
                <i class={"fa-solid text-4xl " <>
            (case error do
               :no_membership -> "fa-user-slash text-red-500"
               :insufficient_membership -> "fa-user-lock text-aurora_orange"
               _ -> "fa-circle-exclamation text-gray-500"
             end)}>
                </i>
              </div>

              <div class="text-center">
                <h3 class="text-lg font-semibold">
                  {case error do
                    :no_membership -> "No eres miembro de esta unidad organizativa"
                    :insufficient_membership -> "Membresía insuficiente"
                    _ -> "Error al cargar"
                  end}
                </h3>

                <p class="mt-2 text-sm text-gray-600">
                  {case error do
                    :no_membership ->
                      "Debes tener una membresía para manifestar tu postura."

                    :insufficient_membership ->
                      "Tu nivel de membresía no permite manifestar posturas."

                    _ ->
                      "Ocurrió un error al cargar los datos. Intenta de nuevo más tarde."
                  end}
                </p>
              </div>

              <.button phx-click="app_modal_close" phx-value-modal={@id} class="primary filled mt-5">
                Aceptar
              </.button>
            </div>
          </:failed>

          <.simple_form
            for={@form}
            id="power_update_form"
            phx-submit="update"
            phx-change="validate"
            phx-target={@myself}
            class="w-full min-w-0 max-w-full"
          >
            <% current = @form[:power_value].value || 50 %>
            <!-- Header -->
            <div class="mt-2 grid grid-cols-1 sm:grid-cols-12 gap-3 text-sm">
              <!-- Card: Unidad organizativa -->
                <div class="min-w-0 sm:col-span-6 flex items-start gap-3 rounded-xl border bg-white p-3 shadow-sm">
                <div class="flex h-10 w-10 shrink-0 items-center justify-center rounded-lg bg-black/90">
                  <i class="fa-solid fa-sitemap rotate-180 text-white"></i>
                </div>

                <div class="min-w-0 flex-1">
                  <div class="text-gray-900 font-medium break-words" title={power_context.ou.ou_name}>
                    {power_context.ou.ou_name}
                  </div>

                  <div class="mt-1">
                    <span class="inline-block max-w-full whitespace-normal break-all rounded px-2 py-0.5 bg-black text-white text-xs font-semibold">
                      {power_context.ou.ou_id}
                    </span>
                  </div>
                </div>
              </div>
              <!-- Card: Poder -->
                <div class="min-w-0 sm:col-span-6 flex items-start gap-3 rounded-xl border bg-white p-3 shadow-sm">
                <div class="flex h-10 w-10 shrink-0 items-center justify-center rounded-lg bg-aurora_orange/10">
                  <i class="fa-solid fa-bolt text-aurora_orange"></i>
                </div>

                <div class="min-w-0 flex-1">
                  <div
                    class="text-gray-900 font-medium break-words"
                    title={power_context.power.power_name}
                  >
                    {power_context.power.power_name}
                  </div>

                  <div class="mt-1">
                    <span class="inline-block max-w-full whitespace-normal break-all rounded px-2 py-0.5 bg-aurora_orange/10 text-aurora_orange text-xs font-semibold">
                      {power_context.power.power_id}
                    </span>
                  </div>
                </div>
              </div>
              <!-- Card: Descripción del poder (ocupa 12 columnas) -->
              <div class="sm:col-span-12 rounded-xl border bg-white p-4 sm:px-3 sm:py-3 shadow-sm">
                <div class="flex min-w-0 items-start gap-2">
                  <i class="fa-solid fa-circle-info shrink-0 mt-1 text-blue-600"></i>
                  <p class="min-w-0 break-words text-sm leading-relaxed text-gray-600">
                    {power_context.power.power_description || "Sin descripción disponible."}
                  </p>
                </div>
              </div>
            </div>
            <!-- Tarjeta de métricas -->
            <div class="mt-4 sm:mt-6 min-w-0 rounded-2xl border shadow-sm p-3 sm:p-6">
              <div class="grid grid-cols-2 divide-x">
                <div class="min-w-0 px-2 text-center">
                  <div class="text-4xl sm:text-6xl font-semibold leading-none">{current}</div>

                  <div class="mt-2 text-sm text-gray-500">Mi postura actual</div>
                </div>

                <div class="min-w-0 px-2 text-center">
                  <div class="text-4xl sm:text-6xl font-semibold text-aurora_orange leading-none">
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
              <% {label, icon, label_class, description} = posture_meta(current) %>
              <div class="mt-3 flex min-w-0 flex-col items-start gap-2 text-sm select-none sm:flex-row sm:gap-4">
                <div class="flex shrink-0 items-center gap-2">
                  <i class={"fa-solid #{icon} #{label_class}"}></i>
                  <span class={"font-semibold #{label_class}"}>{label}</span>
                </div>
                <span class="min-w-0 break-words text-gray-500">{description}</span>
              </div>
            </div>
            <:actions>
              <.button phx-disable-with="..." class="w-full primary filled">Actualizar</.button>
            </:actions>
            <!-- Última actualización -->
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
      </.modal>
    </div>
    """
  end

  @impl true
  def handle_event(
        "validate",
        %{"power_update_form" => params},
        socket
      ) do
    person_id =
      socket.assigns.app_context.current_person &&
        socket.assigns.app_context.current_person.person_id

    ou_id = socket.assigns.app_context.current_ou_id
    power_id = socket.assigns.power_id

    params =
      params
      |> Map.put("person_id", person_id)
      |> Map.put("ou_id", ou_id)
      |> Map.put("power_id", power_id)

    changeset =
      params
      |> AuroraGov.Command.UpdatePower.new()
      |> Map.put(:action, :validate)

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
    person_id =
      socket.assigns.app_context.current_person &&
        socket.assigns.app_context.current_person.person_id

    ou_id = socket.assigns.app_context.current_ou_id
    power_id = socket.assigns.power_id

    update_params =
      params
      |> Map.put("person_id", person_id)
      |> Map.put("ou_id", ou_id)
      |> Map.put("power_id", power_id)

    socket =
      case AuroraGov.Context.PowerContext.update_power!(update_params) do
        {:ok, _result} ->
          send(self(), {:close, :app_modal, socket.assigns.id})

          socket
          |> put_flash(:info, "Actualizado")

        {:error, %Ecto.Changeset{} = changeset} ->
          socket
          |> assign(
            form:
              to_form(
                changeset,
                as: "power_update_form"
              )
          )
          |> put_flash(:error, "No se pudo actualizar")

        {:error, reason} ->
          send(self(), {:close, :app_modal, socket.assigns.id})

          socket
          |> put_flash(:info, "No se pudo actualizar #{inspect(reason)}")
      end

    {:noreply, socket}
  end
end
