defmodule AuroraGovWeb.PersonRegisterLive do
  use AuroraGovWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="mx-auto my-auto w-max-lg w-[750px] h-screen flex flex-col justify-center items-center px-20">
      <img src={~p"/images/brand/logotipo_fondo.webp"} alt="Aurora Logo" class="w-24 mb-5 rounded-lg" />
      <h1 class="text-4xl text-black mb-10">Registrarse</h1>

      <.simple_form
        for={@form}
        id="login_form"
        phx-submit="register"
        phx-change="validate"
        class="border border-gray-300 p-24 w-full py-10 rounded-lg shadow-md"
      >
        <.input field={@form[:person_mail]} type="email" label="Email" required />
        <.input field={@form[:person_name]} type="text" label="Nombre" required />
        <.input field={@form[:person_password]} type="password" label="Password" required />
        <:actions>
          <.button phx-disable-with="..." class="w-full">
            Registrarse <span aria-hidden="true">→</span>
          </.button>
        </:actions>

        <:actions>
          <small>
            <a href={~p"/persons/log_in"} class="text-black hover:underline">
              ¿Ya tienes cuenta? Ingresa aquí
            </a>
          </small>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    email = Phoenix.Flash.get(socket.assigns.flash, :email)
    form = to_form(%{"email" => email}, as: "person")
    {:ok, assign(socket, form: form), temporary_assigns: [form: form]}
  end

  def handle_event("validate", %{"person" => person_params}, socket) do
    changeset =
      person_params
      |> Map.put("person_id", person_params["person_mail"] || "")
      |> AuroraGov.Command.RegisterPerson.new()
      |> Map.put(:action, :validate)

    form = to_form(changeset, as: "person")

    {:noreply, assign(socket, form: form)}
  end

  def handle_event("register", %{"person" => person_params}, socket) do
    person_params = Map.put(person_params, "person_id", person_params["person_mail"] || "")

    case AuroraGov.Context.PersonContext.register_person!(person_params) do
      {:ok, _person} ->
        socket =
          socket
          |> put_flash(:info, "Cuenta creada exitosamente. Por favor, inicia sesión.")

        {:noreply, redirect(socket, to: ~p"/persons/log_in")}

      {:error, changeset} ->
        IO.inspect(changeset, label: "Register Person Error")

        form = to_form(%{changeset | action: :validate}, as: "person")
        {:noreply, assign(socket, form: form)}
    end
  end
end
