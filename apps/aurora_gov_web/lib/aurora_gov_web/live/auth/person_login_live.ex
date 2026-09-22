defmodule AuroraGov.Web.PersonLoginLive do
  use AuroraGov.Web, :live_view

  def render(assigns) do
    ~H"""
    <div class="min-h-screen lg:grid lg:grid-cols-2">
      <aside class="relative hidden lg:flex lg:sticky lg:top-0 lg:h-screen flex-col justify-between overflow-hidden isolate bg-aurora_blue px-16 py-14 text-white">
        <div
          aria-hidden="true"
          class="absolute inset-0 -z-10 bg-cover bg-bottom mix-blend-luminosity opacity-50"
          style={"background-image: url('#{~p"/images/auth/hero_home.webp"}');"}
        >
        </div>
        <div
          aria-hidden="true"
          class="absolute inset-0 -z-10 bg-gradient-to-b from-aurora_blue/70 via-aurora_blue/25 to-aurora_blue/60"
        >
        </div>

        <div class="flex items-center gap-3">
          <img src={~p"/images/brand/logotipo.webp"} alt="Aurora Logo" class="w-10 h-10" />
          <span class="text-xl font-semibold">Aurora<b>Gov</b></span>
        </div>

        <div class="max-w-lg">
          <h1 class="text-5xl font-bold leading-tight tracking-tight">Decidir juntos, con poder real.</h1>
          <p class="mt-6 max-w-md text-lg leading-relaxed text-white/75">
            Tu organización piensa, decide y actúa en conjunto.
          </p>
        </div>

        <p class="text-xs text-white/50">
          AuroraGov v{Application.spec(:aurora_gov, :vsn)} · en desarrollo
        </p>
      </aside>

      <section class="flex min-h-screen flex-col bg-white px-6 py-10 sm:px-10 lg:px-16">
        <div class="mb-12 flex items-center gap-3 lg:hidden">
          <img
            src={~p"/images/brand/logotipo_fondo.webp"}
            alt="Aurora Logo"
            class="w-10 h-10 rounded-full"
          />
          <span class="text-xl font-semibold">Aurora<b>Gov</b></span>
        </div>

        <div class="my-auto w-full max-w-md self-center lg:self-start">
          <h1 class="text-4xl font-bold tracking-tight text-aurora_gray">Iniciar sesión</h1>
          <p class="mt-3 text-gray-500">
            ¿No tienes cuenta?
            <a href={~p"/persons/register"} class="font-semibold text-aurora_blue_light hover:underline">
              Regístrate aquí
            </a>
          </p>

          <.form
            for={@form}
            id="login_form"
            action={~p"/persons/log_in"}
            phx-update="ignore"
            class="mt-10 space-y-6"
          >
            <div>
              <label for="login_email" class="block text-sm font-semibold text-aurora_gray">Email</label>
              <input
                type="email"
                id="login_email"
                name={@form[:id].name}
                value={@form[:id].value}
                required
                autocomplete="email"
                placeholder="tucorreo@ejemplo.org"
                class="mt-2 block h-12 w-full rounded-lg border border-gray-300 px-4 text-base text-aurora_gray shadow-sm placeholder:text-gray-400 focus:border-aurora_blue focus:outline-none focus:ring-4 focus:ring-aurora_blue/10"
              />
            </div>

            <div>
              <label for="login_password" class="block text-sm font-semibold text-aurora_gray">
                Contraseña
              </label>
              <div class="relative mt-2">
                <input
                  type="password"
                  id="login_password"
                  name={@form[:password].name}
                  required
                  autocomplete="current-password"
                  class="block h-12 w-full rounded-lg border border-gray-300 pl-4 pr-12 text-base text-aurora_gray shadow-sm focus:border-aurora_blue focus:outline-none focus:ring-4 focus:ring-aurora_blue/10"
                />
                <button
                  type="button"
                  aria-label="Mostrar u ocultar contraseña"
                  phx-click={
                    JS.toggle_attribute({"type", "password", "text"}, to: "#login_password")
                    |> JS.toggle_class("hidden", to: "#login_password_show")
                    |> JS.toggle_class("hidden", to: "#login_password_hide")
                  }
                  class="absolute inset-y-0 right-0 flex w-12 items-center justify-center text-gray-400 hover:text-aurora_gray focus:outline-none focus-visible:text-aurora_blue"
                >
                  <span id="login_password_show"><i class="fa-regular fa-eye"></i></span>
                  <span id="login_password_hide" class="hidden">
                    <i class="fa-regular fa-eye-slash"></i>
                  </span>
                </button>
              </div>
            </div>

            <label class="flex items-center gap-3 text-sm text-aurora_gray">
              <input type="hidden" name={@form[:remember_me].name} value="false" />
              <input
                type="checkbox"
                id="login_remember_me"
                name={@form[:remember_me].name}
                value="true"
                checked
                class="h-5 w-5 rounded border-gray-300 text-aurora_blue focus:ring-2 focus:ring-aurora_blue/30 focus:ring-offset-0"
              />
              Recordarme
            </label>

            <button
              type="submit"
              phx-disable-with="Ingresando..."
              class="h-12 w-full rounded-lg bg-aurora_orange text-base font-semibold text-white shadow-sm transition hover:brightness-95 active:brightness-90 focus:outline-none focus-visible:ring-4 focus-visible:ring-aurora_orange/30"
            >
              Ingresar
            </button>
          </.form>
        </div>
      </section>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    email = Phoenix.Flash.get(socket.assigns.flash, :email)
    form = to_form(%{"email" => email}, as: "person")
    {:ok, assign(socket, form: form), temporary_assigns: [form: form]}
  end
end
