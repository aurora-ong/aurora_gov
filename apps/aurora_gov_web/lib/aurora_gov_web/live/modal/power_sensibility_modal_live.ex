defmodule AuroraGovWeb.App.Power.PowerSensibilityModalLive do
  use AuroraGovWeb, :live_component
  alias Phoenix.LiveView.AsyncResult

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(:context, assigns.context)
      |> assign(:power_id, assigns.power_id)
      |> assign(
        form:
          to_form(
            AuroraGov.Forms.SensitivityForm.changeset(%AuroraGov.Forms.SensitivityForm{}, %{}),
            as: "power_update_form"
          )
      )

    {:ok, socket}
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
        id="login_form"
        phx-submit="step_0_next"
        phx-change="validate"
        phx-target={@myself}
        class="w-full"
      >
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
      AuroraGov.Forms.SensitivityForm.changeset(%AuroraGov.Forms.SensitivityForm{}, params)
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
end
