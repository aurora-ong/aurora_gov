defmodule AuroraGovWeb.GovLiveComponent do
  use AuroraGovWeb, :live_component

  @impl true
  def update(%{info: {:trigger_validation, _field_name}} = assigns, socket) do
    form_data = socket.assigns.form.params || %{}
    IO.inspect(assigns, label: "Update GovLiveComponent")

    changeset =
      form_data
      |> AuroraGov.Command.CreateProposal.new()
      |> Map.put(:action, :validate)

    {:ok, assign(socket, form: to_form(changeset, as: "proposal"))}
  end

  def update(assigns, socket) do
    # Inicializa el formulario si no está presente
    socket =
      socket
      |> assign(assigns)
      |> assign_new(:form, fn ->
        to_form(%{}, as: "proposal")
      end)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto my-auto w-max-lg flex flex-col justify-center items-start">
      <h1 class="text-4xl text-black mb-5"><i class="fa-solid fa-hand text-3xl mr-3"></i>Gobernar</h1>

      <h2 class="text-xl mb-10">
        Utiliza este formulario para proponer una decisión. Reune los votos del resto de los integrantes para promulgarla.
      </h2>

      <.simple_form
        for={@form}
        id="login_form"
        phx-submit="register"
        phx-change="validate"
        phx-target={@myself}
        class="w-full"
      >
        <%!-- <.input field={@form[:proposal_title]} type="text" label="Título propuesta" required />
        <.input
          field={@form[:proposal_description]}
          type="textarea"
          label="Descripción propuesta"
          description="Describe como esta propuesta contribuye al objetivo de la unidad."
          required
        /> --%>
        <div class="flex flex-row gap-4 justify-between items-center flex-nowrap border border-gray-200 py-5 bg-gray-50 px-5 rounded-lg">
          <div class="flex flex-col gap-5 basis-1/2">
            <.live_component
              module={AuroraGovWeb.OUSelectorComponent}
              parent_module={__MODULE__}
              parent_id="gov-modal-component"
              id="proposal_ou_origin"
              field={@form[:proposal_ou_origin]}
              label="Unidad Origen"
              ou_tree={@ou_tree}
              only_if_member?={true}
              current_person_id="p.delgado@gmail.com"
            />
          </div>
           <i class="fa-solid fa-arrow-right text-6xl mx-10 self-center"></i>
          <div class="flex flex-col basis-1/2 gap-5 justify-center">
            <.live_component
              module={AuroraGovWeb.OUSelectorComponent}
              parent_module={__MODULE__}
              parent_id="gov-modal-component"
              id="proposal_ou_end"
              field={@form[:proposal_ou_end]}
              label="Unidad Destino"
              ou_tree={@ou_tree}
              only_if_member?={false}
              current_person_id="p.delgado@gmail.com"
            />
          </div>
        </div>
        <div class="flex flex-row gap-4 justify-between items-center flex-nowrap">
          <div class="flex flex-col gap-5 basis-1/2">
            <.input field={@form[:proposal_power]} type="text" label="Poder" required />
          </div>

          <div class="flex flex-col basis-1/2 gap-5 justify-center px-10">
            <p class="w-fit text-center text-sm bg-aurora_orange/50 px-10 py-5 rounded-lg">
              Necesitarás reunir el apoyo de al menos <strong>3 personas</strong>
              para que esta propuesta sea promulgada.
            </p>
          </div>
        </div>

        <.live_component
          module={AuroraGovWeb.DynamicCommandFormComponent}
          id="register-form"
          form={@form}
          command_module={AuroraGov.Command.StartMembership}
          validate_event="validate"
          submit_event="submit"
          target={@myself}
        />
        <:actions>
          <.button phx-disable-with="Logging in..." class="w-full">
            Siguiente <span aria-hidden="true">→</span>
          </.button>
        </:actions>

        <%!-- <:actions>
          <small>
            <a href={~p"/persons/log_in"} class="text-black hover:underline">
              ¿Ya tienes cuenta? Ingresa aquí
            </a>
          </small>
        </:actions> --%>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def handle_event("validate", params, socket) do
    IO.inspect(params, label: "Validate Params")

    changeset =
      params["proposal"]
      |> AuroraGov.Command.CreateProposal.new()
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset, as: "proposal"))}
  end

  # def handle_event("validate", %{"person" => person_params}, socket) do
  #   changeset =
  #     person_params
  #     |> Map.put("person_id", person_params["person_mail"] || "")
  #     |> AuroraGov.Command.RegisterPerson.new()
  #     |> Map.put(:action, :validate)

  #   form = to_form(changeset, as: "person")

  #   {:noreply, assign(socket, form: form)}
  # end

  def handle_event("register", %{"person" => person_params}, socket) do
    person_params = Map.put(person_params, "person_id", person_params["person_mail"] || "")

    case AuroraGov.Context.PersonContext.register_person!(person_params) do
      {:ok, _person} ->
        socket =
          socket
          |> put_flash(:info, "Cuenta creada exitosamente. Por favor, inicia sesión.")

        # PUSH REDIRECT
        {:noreply, redirect(socket, to: ~p"/persons/log_in")}

      {:error, changeset} ->
        IO.inspect(changeset, label: "Register Person Error")

        form = to_form(%{changeset | action: :validate}, as: "person")
        {:noreply, assign(socket, form: form)}
    end
  end
end
