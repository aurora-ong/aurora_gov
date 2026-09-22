defmodule AuroraGov.Web.PersonRegisterLive do
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
          <h1 class="text-5xl font-bold leading-tight tracking-tight">
            Decidamos juntos el rumbo de tu organización.
          </h1>
          <ul class="mt-8 space-y-4 text-lg leading-relaxed text-white/80">
            <li class="flex items-start gap-4">
              <i class="fa-solid fa-check mt-1.5 text-aurora_orange"></i>
              <span>Incide con poder real en cada decisión colectiva</span>
            </li>
            <li class="flex items-start gap-4">
              <i class="fa-solid fa-check mt-1.5 text-aurora_orange"></i>
              <span>Colabora informado y alineado con tu comunidad, en tiempo real</span>
            </li>
            <li class="flex items-start gap-4">
              <i class="fa-solid fa-check mt-1.5 text-aurora_orange"></i>
              <span>Construye con confianza: cada acción queda registrada</span>
            </li>
          </ul>
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
          <h1 class="text-4xl font-bold tracking-tight text-aurora_gray">Crear cuenta</h1>
          <p class="mt-3 text-gray-500">
            ¿Ya tienes cuenta?
            <a href={~p"/persons/log_in"} class="font-semibold text-aurora_blue_light hover:underline">
              Ingresa aquí
            </a>
          </p>

          <.form
            for={@form}
            id="register_form"
            phx-submit="register"
            phx-change="validate"
            class="mt-10 space-y-6"
          >
            <div>
              <label for="register_name" class="block text-sm font-semibold text-aurora_gray">
                Nombre completo
              </label>
              <input
                type="text"
                id="register_name"
                name={@form[:person_name].name}
                value={@form[:person_name].value}
                required
                autocomplete="name"
                placeholder="Camila Saez"
                class="mt-2 block h-12 w-full rounded-lg border border-gray-300 px-4 text-base text-aurora_gray shadow-sm placeholder:text-gray-400 focus:border-aurora_blue focus:outline-none focus:ring-4 focus:ring-aurora_blue/10"
              />
              <p :for={msg <- field_errors(@form[:person_name])} class="mt-2 text-sm text-rose-600">
                {msg}
              </p>
            </div>

            <div>
              <label for="register_email" class="block text-sm font-semibold text-aurora_gray">
                Email
              </label>
              <input
                type="email"
                id="register_email"
                name={@form[:person_mail].name}
                value={@form[:person_mail].value}
                required
                autocomplete="email"
                placeholder="tucorreo@ejemplo.org"
                class="mt-2 block h-12 w-full rounded-lg border border-gray-300 px-4 text-base text-aurora_gray shadow-sm placeholder:text-gray-400 focus:border-aurora_blue focus:outline-none focus:ring-4 focus:ring-aurora_blue/10"
              />
              <p :for={msg <- field_errors(@form[:person_mail])} class="mt-2 text-sm text-rose-600">
                {msg}
              </p>
            </div>

            <div>
              <label for="register_password" class="block text-sm font-semibold text-aurora_gray">
                Contraseña
              </label>
              <div class="relative mt-2">
                <input
                  type="password"
                  id="register_password"
                  name={@form[:person_password].name}
                  value={@form[:person_password].value}
                  required
                  autocomplete="new-password"
                  phx-debounce="150"
                  phx-focus="password_focused"
                  aria-describedby="register_password_strength"
                  class="block h-12 w-full rounded-lg border border-gray-300 pl-4 pr-12 text-base text-aurora_gray shadow-sm focus:border-aurora_blue focus:outline-none focus:ring-4 focus:ring-aurora_blue/10"
                />
                <button
                  type="button"
                  aria-label="Mostrar u ocultar contraseña"
                  phx-click={
                    JS.toggle_attribute({"type", "password", "text"}, to: "#register_password")
                    |> JS.toggle_class("hidden", to: "#register_password_show")
                    |> JS.toggle_class("hidden", to: "#register_password_hide")
                  }
                  class="absolute inset-y-0 right-0 flex w-12 items-center justify-center text-gray-400 hover:text-aurora_gray focus:outline-none focus-visible:text-aurora_blue"
                >
                  <span id="register_password_show"><i class="fa-regular fa-eye"></i></span>
                  <span id="register_password_hide" class="hidden">
                    <i class="fa-regular fa-eye-slash"></i>
                  </span>
                </button>
              </div>

              <div
                :if={@show_password_hint}
                id="register_password_strength"
                class="mt-3 flex items-center gap-3"
                aria-live="polite"
              >
                <div class="flex flex-1 gap-1.5">
                  <span class={["h-1.5 flex-1 rounded-full", strength_segment_class(@password_strength, 1)]}>
                  </span>
                  <span class={["h-1.5 flex-1 rounded-full", strength_segment_class(@password_strength, 2)]}>
                  </span>
                  <span class={["h-1.5 flex-1 rounded-full", strength_segment_class(@password_strength, 3)]}>
                  </span>
                </div>
                <span class={[
                  "w-16 text-right text-sm font-semibold",
                  strength_label_class(@password_strength)
                ]}>
                  {strength_label(@password_strength)}
                </span>
              </div>
              <p :if={@show_password_hint} class="mt-2 text-xs text-gray-500">
                {strength_hint(@password_strength)}
              </p>

              <p :for={msg <- field_errors(@form[:person_password])} class="mt-2 text-sm text-rose-600">
                {msg}
              </p>
            </div>

            <button
              type="submit"
              phx-disable-with="Creando cuenta..."
              class="h-12 w-full rounded-lg bg-aurora_orange text-base font-semibold text-white shadow-sm transition hover:brightness-95 active:brightness-90 focus:outline-none focus-visible:ring-4 focus-visible:ring-aurora_orange/30"
            >
              Crear cuenta
            </button>

            <p class="text-sm text-gray-500">
              Al continuar aceptas las normas de participación de la plataforma.
            </p>
          </.form>
        </div>
      </section>
    </div>
    """
  end

  defp field_errors(%Phoenix.HTML.FormField{} = field) do
    if Phoenix.Component.used_input?(field) do
      Enum.map(field.errors, &error_message/1)
    else
      []
    end
  end

  defp error_message({"can't be blank", _opts}), do: "Este campo es obligatorio."
  defp error_message({"has invalid format", _opts}), do: "Ingresa un correo válido."

  defp error_message({"should be at least %{count} character(s)", opts}),
    do: "Usa al menos #{opts[:count]} caracteres."

  defp error_message({"should be at most %{count} character(s)", opts}),
    do: "Usa como máximo #{opts[:count]} caracteres."

  defp error_message({msg, _opts}), do: msg

  defp strength_segment_class(strength, position) do
    filled =
      case strength do
        :debil -> 1
        :buena -> 2
        :fuerte -> 3
        _otro -> 0
      end

    cond do
      position > filled -> "bg-aurora_gray_light"
      strength == :debil -> "bg-rose-600"
      true -> "bg-emerald-600"
    end
  end

  defp strength_label(:debil), do: "Débil"
  defp strength_label(:buena), do: "Buena"
  defp strength_label(:fuerte), do: "Fuerte"
  defp strength_label(_otro), do: ""

  defp strength_label_class(:debil), do: "text-rose-600"
  defp strength_label_class(:buena), do: "text-emerald-700"
  defp strength_label_class(:fuerte), do: "text-emerald-700"
  defp strength_label_class(_otro), do: "text-gray-400"

  defp strength_hint(:buena), do: "Agrega más caracteres o símbolos para hacerla fuerte."
  defp strength_hint(:fuerte), do: "Contraseña fuerte."

  defp strength_hint(_otro),
    do:
      "Usa al menos #{AuroraGov.Web.PasswordStrength.minimum_length()} caracteres y combina letras, números o símbolos."

  def mount(_params, _session, socket) do
    email = Phoenix.Flash.get(socket.assigns.flash, :email)
    form = to_form(%{"email" => email}, as: "person")

    {:ok, assign(socket, form: form, password_strength: :vacia, show_password_hint: false),
     temporary_assigns: [form: form]}
  end

  def handle_event("validate", %{"person" => person_params}, socket) do
    changeset =
      person_params
      |> Map.put("person_id", person_params["person_mail"] || "")
      |> AuroraGov.Command.RegisterPerson.new()
      |> Map.put(:action, :validate)

    form = to_form(changeset, as: "person")
    password = person_params["person_password"]
    password_strength = AuroraGov.Web.PasswordStrength.score(password)
    show_password_hint = socket.assigns.show_password_hint or password not in [nil, ""]

    {:noreply,
     assign(socket,
       form: form,
       password_strength: password_strength,
       show_password_hint: show_password_hint
     )}
  end

  def handle_event("password_focused", _params, socket) do
    {:noreply, assign(socket, show_password_hint: true)}
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
