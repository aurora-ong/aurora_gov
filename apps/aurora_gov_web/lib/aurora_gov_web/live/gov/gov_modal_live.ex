defmodule AuroraGovWeb.GovLiveComponent do
  use AuroraGovWeb, :live_component

  @impl true
  def update(%{info: {:ou_selected, field_name, field_data}} = assigns, socket) do
    changeset =
      socket.assigns.form.source
      |> Ecto.Changeset.change(Map.new() |> Map.put(field_name, field_data))
      |> Map.put(:action, :validate)

    {:ok, assign(socket, form: to_form(changeset, as: "proposal"))}
  end

  def update(assigns, socket) do
    # Inicializa el formulario si no está presente
    socket =
      socket
      |> assign(assigns)
      |> assign_new(:form, fn ->
        to_form(AuroraGov.Command.CreateProposal.new(), as: "proposal")
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
            <.input
              phx-change="change_power_type"
              phx-target={@myself}
              field={@form[:proposal_power]}
              type="select"
              label="Poder"
              options={[nil] ++ AuroraGov.CommandUtils.all_proposable_modules_select()}
              description="Selecciona el poder que deseas proponer. Este poder será ejecutado por la unidad destino."
            />
            { inspect(@form[:proposal_power].errors)}
            <%!-- <.input field={@form[:proposal_power]} type="text" label="Poder" required /> --%>
          </div>

          <div class="flex flex-col basis-1/2 gap-5 justify-center px-10">
            <p class="w-fit text-center text-sm bg-aurora_orange/50 px-10 py-5 rounded-lg">
              Necesitarás reunir el apoyo de al menos <strong>3 personas</strong>
              para que esta propuesta sea promulgada.
            </p>
          </div>
        </div>

        <.live_component
          :if={@form[:proposal_power].value != nil and @form[:proposal_power].value != ""}
          module={AuroraGovWeb.DynamicCommandFormComponent}
          id="register-form"
          form={@form_power}
          command_module={AuroraGov.CommandUtils.find_command_by_id(@form[:proposal_power].value)}
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
        </:actions> --%> {inspect(
          @form[:proposal_power].value
        )} <%!-- {inspect(
                assigns[:form_power]
              )}  --%>
        <br /> {inspect(assigns.form)}
      </.simple_form>
    </div>
    """
  end

  @impl true
  @spec handle_event(<<_::64>>, nil | maybe_improper_list() | map(), any()) :: {:noreply, any()}
  def handle_event("validate", %{"proposal" => proposal_params} = x, socket) do
    IO.inspect(x, label: "Validate Params")
    IO.inspect(proposal_params, label: "Validate Params")

    changeset =
      proposal_params
      |> AuroraGov.Command.CreateProposal.new()
      |> Map.put(:action, :validate)



    socket =
      socket
      |> assign(form: to_form(changeset, as: "proposal"))

    {:noreply, socket}
  end

  def handle_event(
        "change_power_type",
        %{"proposal" => %{"proposal_power" => power_id}},
        socket
      ) do
    IO.inspect(power_id, label: "Change Power Type")
    IO.inspect(socket.assigns.form.source, label: "PARAMS")

    changeset =
      socket.assigns.form.source
      |> Ecto.Changeset.change(%{proposal_power: power_id})
      |> Map.put(:action, :validate)

    power_changeset =
      if power_id != nil and power_id != "" do
        AuroraGov.CommandUtils.find_command_by_id(power_id).new()
        |> Map.put(:action, :validate)
      else
        %{}
      end

    socket =
      socket
      |> assign(form: to_form(changeset, as: "proposal"))
      |> assign(form_power: to_form(power_changeset, as: "power"))

    # Hacer algo con el nuevo valor seleccionado
    {:noreply, socket}
  end
end
