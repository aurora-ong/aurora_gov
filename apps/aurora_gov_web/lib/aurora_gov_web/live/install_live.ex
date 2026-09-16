defmodule AuroraGov.Web.Live.InstallLive do
  use AuroraGov.Web, :live_view

  def mount(_params, _session, socket) do
    if Enum.empty?(AuroraGov.Context.OUContext.list_ou()) do
      # Initialize forms
      person_changeset = AuroraGov.Command.RegisterPerson.new(%{}) |> Map.put(:action, :validate)
      ou_changeset = AuroraGov.Command.CreateOU.new(%{}) |> Map.put(:action, :validate)

      socket =
        socket
        |> assign(:step, :person)
        |> assign(:person_form, to_form(person_changeset, as: "person"))
        |> assign(:ou_form, to_form(ou_changeset, as: "ou"))
        |> assign(:person_params, %{})

      {:ok, socket}
    else
      {:ok, redirect(socket, to: "/app")}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="mx-auto my-auto w-max-lg w-187.5 h-screen flex flex-col justify-center items-center px-20">
      <img src={~p"/images/brand/logotipo_fondo.webp"} alt="Aurora Logo" class="w-24 mb-5 rounded-lg" />
      <h1 class="text-4xl text-black mb-10">
        <%= if @step == :person do %>
          Instalación (1/2): Administrador
        <% else %>
          Instalación (2/2): Organización
        <% end %>
      </h1>

      <%= if @step == :person do %>
        <.simple_form
          for={@person_form}
          id="person_form"
          phx-submit="next_step"
          phx-change="validate_person"
          class="border border-gray-300 p-24 w-full py-10 rounded-lg shadow-md"
        >
          <.input field={@person_form[:person_mail]} type="email" label="Email" required />
          <.input field={@person_form[:person_name]} type="text" label="Nombre completo" required />
          <.input field={@person_form[:person_password]} type="password" label="Contraseña" required />
          <:actions>
            <.button phx-disable-with="..." class="w-full">
              Siguiente <span aria-hidden="true">→</span>
            </.button>
          </:actions>
        </.simple_form>
      <% else %>
        <.simple_form
          for={@ou_form}
          id="ou_form"
          phx-submit="finalize"
          phx-change="validate_ou"
          class="border border-gray-300 p-24 w-full py-10 rounded-lg shadow-md"
        >
          <.input field={@ou_form[:ou_slug]} type="text" label="Identificador de la Organización (slug)" placeholder="ej: mi_organizacion" required />
          <.input field={@ou_form[:ou_name]} type="text" label="Nombre de la Organización" required />
          <.input field={@ou_form[:ou_goal]} type="text" label="Objetivo" required />
          <.input field={@ou_form[:ou_description]} type="textarea" label="Descripción" required />

          <:actions>
            <.button type="button" phx-click="prev_step" class="w-1/3 bg-gray-500 hover:bg-gray-600">
              <span aria-hidden="true">←</span> Atrás
            </.button>
            <.button phx-disable-with="..." class="w-2/3">
              Finalizar Instalación
            </.button>
          </:actions>
        </.simple_form>
      <% end %>
    </div>
    """
  end

  def handle_event("validate_person", %{"person" => person_params}, socket) do
    changeset =
      person_params
      |> Map.put("person_id", person_params["person_mail"] || "")
      |> AuroraGov.Command.RegisterPerson.new()
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, person_form: to_form(changeset, as: "person"), person_params: person_params)}
  end

  def handle_event("next_step", %{"person" => person_params}, socket) do
    # Validate one more time before passing
    changeset =
      person_params
      |> Map.put("person_id", person_params["person_mail"] || "")
      |> AuroraGov.Command.RegisterPerson.new()

    if changeset.valid? do
      {:noreply, assign(socket, step: :organization, person_params: person_params)}
    else
      {:noreply, assign(socket, person_form: to_form(Map.put(changeset, :action, :validate), as: "person"))}
    end
  end

  def handle_event("prev_step", _, socket) do
    {:noreply, assign(socket, step: :person)}
  end

  def handle_event("validate_ou", %{"ou" => ou_params}, socket) do
    changeset =
      ou_params
      |> AuroraGov.Command.CreateOU.new()
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, ou_form: to_form(changeset, as: "ou"))}
  end

  def handle_event("finalize", %{"ou" => ou_params}, socket) do
    person_params = socket.assigns.person_params
    person_id = person_params["person_mail"]

    # Validation step 1
    ou_changeset = AuroraGov.Command.CreateOU.new(ou_params)

    if ou_changeset.valid? do
      person_params = Map.put(person_params, "person_id", person_id)

      with {:ok, ^person_id} <- AuroraGov.Context.PersonContext.register_person!(person_params),
           {:ok, ou_command} <- Ecto.Changeset.apply_action(ou_changeset, :insert),
           :ok <- AuroraGov.dispatch(ou_command, consistency: :strong),
           ou_id = ou_command.ou_id,
           {:ok, membership_command} <- AuroraGov.Command.StartMembership.new(%{person_id: person_id, ou_id: ou_id}) |> Ecto.Changeset.apply_action(:insert),
           :ok <- AuroraGov.dispatch(membership_command, consistency: :strong),
           {:ok, promote_command} <- AuroraGov.Command.PromoteMembership.new(%{person_id: person_id, ou_id: ou_id}) |> Ecto.Changeset.apply_action(:insert),
           :ok <- AuroraGov.dispatch(promote_command, consistency: :strong) do

        socket =
          socket
          |> put_flash(:info, "Sistema inicializado correctamente. Por favor, inicia sesión con tu nueva cuenta de administrador.")
          |> redirect(to: ~p"/persons/log_in")

        {:noreply, socket}
      else
        {:error, %Ecto.Changeset{} = err_changeset} ->
          # It could be an error in Person registration
          IO.inspect(err_changeset, label: "InstallLive Error: Changeset")
          socket = put_flash(socket, :error, "Error en la instalación: Verifica los datos ingresados.")
          {:noreply, assign(socket, step: :person, person_form: to_form(err_changeset, as: "person"))}

        {:error, reason} ->
          IO.inspect(reason, label: "InstallLive Error: Dispatch")
          socket = put_flash(socket, :error, "Error interno en la instalación. Inténtalo de nuevo.")
          {:noreply, socket}
      end
    else
      {:noreply, assign(socket, ou_form: to_form(Map.put(ou_changeset, :action, :validate), as: "ou"))}
    end
  end
end
