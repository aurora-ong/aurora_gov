defmodule AuroraGov.Web.PersonLoginLive do
  use AuroraGov.Web, :live_view

  def render(assigns) do
    ~H"""
    <div class="mx-auto my-auto max-w-sm h-screen flex flex-col justify-center items-center">
      <img src={~p"/images/brand/logotipo_fondo.webp"} alt="Aurora Logo" class="w-32 mb-5 rounded-lg" />
      <h1 class="text-4xl text-black mb-10">Iniciar sesión</h1>

      <.simple_form
        for={@form}
        id="login_form"
        action={~p"/persons/log_in"}
        phx-update="ignore"
        class="border border-gray-300 p-16 rounded-lg shadow-md"
      >
        <.input field={@form[:id]} type="email" label="Email" required />
        <.input field={@form[:password]} type="password" label="Password" required />
        <:actions>
          <.input field={@form[:remember_me]} type="checkbox" label="Recordarme por 7 días" />
        </:actions>

        <:actions>
          <.button phx-disable-with="..." class="w-full">
            Ingresar <span aria-hidden="true">→</span>
          </.button>
        </:actions>

        <:actions>
          <small>
            <a href={~p"/persons/register"} class="text-black hover:underline">
              ¿No tienes cuenta? Regístrate aquí
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
end
