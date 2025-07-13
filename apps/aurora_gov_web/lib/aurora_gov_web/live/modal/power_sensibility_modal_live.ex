defmodule AuroraGovWeb.App.Power.PowerSensibilityModalLive do
  alias AuroraGov.Context.PowerContext
  use AuroraGovWeb, :live_component
  alias Phoenix.LiveView.AsyncResult

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
      Task.async(fn -> PowerContext.get_ou_power(ou_id, power_id) end)
    ]

    Task.await_many(tasks)
  end

  @impl true
  def handle_async(:load_data, {:ok, [result_power, result_ou_power] = r}, socket) do
    IO.inspect(r)

    socket =
      socket
      |> assign(
        :power_update_context,
        AsyncResult.ok(%{
          power: result_power,
          ou_power: result_ou_power
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
      <h1 class="text-4xl text-black mb-5"><i class="fa-solid fa-hand text-3xl mr-3"></i>Mi Poder</h1>

      <h2 class="text-xl mb-10">
        {@power_id}
      </h2>

      <.simple_form
        for={@form}
        id="power_update_form"
        phx-submit="update"
        phx-change="validate"
        phx-target={@myself}
        class="w-full"
      >
        <.async_result :let={power_context} assign={@power_update_context}>
          <:loading>
            <.loading_spinner></.loading_spinner>
          </:loading>

          <:failed :let={_failure}>error loading</:failed>

          <p class="mt-2 text-3xl text-gray-600">
            Valor actual: <strong>{@form[:power_value].value || 50}</strong>
          </p>

          <.input field={@form[:power_value]} type="range" min="0" max="100" step="5" class="w-full" />
          <p class="mt-1 text-lg text-gray-500 italic">
            {case @form[:power_value].value do
              v when is_integer(v) and v < 33 ->
                "Postura Ágil"

              v when is_integer(v) and v < 75 ->
                "Postura Flexible"

              v when is_integer(v) and v <= 100 ->
                "Postura Cautelosa"

              _ ->
                ""
            end}
          </p>
        </.async_result>

        <:actions>
          <.button phx-disable-with="..." class="w-full">
            Actualizar
          </.button>
        </:actions>
      </.simple_form>
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
          send_update(PowerPanelComponent,
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
