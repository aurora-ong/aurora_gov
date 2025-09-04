defmodule AuroraGovWeb.GovLiveComponent do
  use AuroraGovWeb, :live_component
  alias Phoenix.LiveView.AsyncResult

  @impl true
  def mount(socket) do
    IO.inspect(socket.assigns)

    socket =
      socket
      |> assign(:ou_tree, AsyncResult.loading())

    {:ok, socket}
  end

  @impl true
  def update(%{info: {:ou_selected, field_name, nil}}, socket) do
    IO.inspect("OU_clear #{field_name}")

    params =
      socket.assigns.step_0_form_proposal.params
      |> Map.put(to_string(field_name), nil)

    {:noreply, socket} = handle_event("step_0_validate", %{"proposal" => params}, socket)

    {:ok, socket}
  end

  @impl true
  def update(%{info: {:ou_selected, field_name, field_data}}, socket) do
    IO.inspect("OU Selected #{field_name} #{field_data}")

    params =
      socket.assigns.step_0_form_proposal.params
      |> Map.put(to_string(field_name), field_data)

    {:noreply, socket} = handle_event("step_0_validate", %{"proposal" => params}, socket)

    {:ok, socket}
  end

  def update(assigns, socket) do
    # Inicializa el formulario si no está presente

    socket =
      socket
      |> assign(assigns)
      |> start_async(:load_data, fn ->
        AuroraGov.Context.OUContext.get_ou_tree_with_membership(
          assigns[:current_person].person_id
        )
      end)
      |> assign_new(:step_0_form_proposal, fn ->
        IO.inspect(assigns[:initial_values], label: "Initial values")

        form_proposal_params = assigns[:initial_values] || %{}

        form_proposal_params
        |> AuroraGov.Command.CreateProposal.handle_validate_step(0)
        |> to_form(as: "proposal")
      end)
      |> assign_new(:step_0_ou_power_detail, fn -> nil end)
      |> then(fn socket ->
        proposal_power = Map.get(assigns[:initial_values], "proposal_power", nil)

        if proposal_power != nil do
          power_changeset =
            AuroraGov.CommandUtils.find_command_by_id(proposal_power).new(
              assigns[:initial_values]
            )

          socket
          |> assign(step_1_form_power: to_form(power_changeset, as: "power"))
        else
          socket
        end
      end)
      |> assign_new(:step_2_form_proposal, fn ->
        form_proposal_params = assigns[:initial_values] || %{}

        form_proposal_params
        |> AuroraGov.Command.CreateProposal.handle_validate_step(1)
        |> to_form(as: "proposal")
      end)
      |> assign_new(:step, fn -> 0 end)

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
        :if={@step == 0}
        for={@step_0_form_proposal}
        id="login_form"
        phx-submit="step_0_next"
        phx-change="step_0_validate"
        phx-target={@myself}
        class="w-full"
      >
        <.async_result :let={ou_tree} assign={@ou_tree}>
          <:loading>
            <.loading_spinner></.loading_spinner>
          </:loading>

          <:failed :let={_failure}>there was an error loading the organization</:failed>

          <div class="flex flex-row gap-4 justify-between items-start flex-nowrap">
            <div class="flex flex-col gap-5 basis-1/2">
              <.live_component
                module={AuroraGovWeb.OUSelectorComponent}
                parent_module={__MODULE__}
                parent_id="gov-modal-component"
                id="proposal_ou_origin"
                field={@step_0_form_proposal[:proposal_ou_origin]}
                label="Unidad Origen"
                ou_tree={ou_tree}
                only_if_member?={true}
                current_person_id="p.delgado@gmail.com"
                description="Debes pertenecer a esta unidad."
                enabled="false"
              />
              <.input
                field={@step_0_form_proposal[:proposal_power]}
                type="select"
                label="Acción"
                options={[nil] ++ AuroraGov.CommandUtils.all_proposable_modules_select()}
                description="Esta acción será ejecutada en la unidad destino."
              />
            </div>
             <i class="fa-solid fa-arrow-right text-6xl mx-10 self-center"></i>
            <div class="flex flex-col basis-1/2 gap-5 justify-center">
              <.live_component
                module={AuroraGovWeb.OUSelectorComponent}
                parent_module={__MODULE__}
                parent_id="gov-modal-component"
                id="proposal_ou_end"
                field={@step_0_form_proposal[:proposal_ou_end]}
                label="Unidad Destino"
                ou_tree={ou_tree}
                only_if_member?={false}
                current_person_id="p.delgado@gmail.com"
                description="Unidad donde se ejecutará la acción."
              />
              <div :if={@step_0_ou_power_detail != nil}>
                <.async_result :let={ou_power} assign={@step_0_ou_power_detail}>
                  <:loading>
                    <.loading_spinner></.loading_spinner>
                  </:loading>

                  <.live_component
                    module={AuroraGovWeb.Components.Power.PowerCardComponent}
                    id="power-card"
                    show_actions={false}
                    power_id={@step_0_form_proposal[:proposal_power].value}
                    power_info={
                      AuroraGov.Context.PowerContext.get_power_metadata(
                        @step_0_form_proposal[:proposal_power].value
                      )
                    }
                    ou_power={ou_power}
                    parent_target={@myself}
                  />
                </.async_result>
              </div>
            </div>
          </div>

          <div class="flex flex-row gap-4 justify-between items-center flex-nowrap">
            <div class="flex flex-col gap-5 basis-1/2"></div>

            <div class="flex flex-col basis-1/2 gap-5 justify-center px-10"></div>
          </div>
        </.async_result>

        <:actions>
          <.button phx-disable-with="..." class="w-full">
            Siguiente <span aria-hidden="true">→</span>
          </.button>
        </:actions>
      </.simple_form>

      <.simple_form
        :if={@step == 1}
        for={@step_1_form_power}
        id="proposal_details_form"
        phx-submit="step_1_next"
        phx-change="step_1_validate"
        phx-target={@myself}
        class="w-full"
      >
        {inspect(@proposal_data)} <br /> {inspect(@step_1_form_power)}
        <.live_component
          module={AuroraGovWeb.DynamicCommandFormComponent}
          id="proposal-power_form"
          form={@step_1_form_power}
          command_module={AuroraGov.CommandUtils.find_command_by_id(@proposal_data.proposal_power)}
        />
        <:actions>
          <.button
            phx-click="step_back"
            phx-value-step="0"
            phx-target={@myself}
            phx-disable-with="..."
            class="w-full"
            type="button"
          >
            Atrás
          </.button>

          <.button phx-disable-with="..." class="w-full">
            Siguiente
          </.button>
        </:actions>
      </.simple_form>

      <.simple_form
        :if={@step == 2}
        for={@step_2_form_proposal}
        id="proposal_details_form"
        phx-submit="step_2_next"
        phx-change="step_2_validate"
        phx-target={@myself}
        class="w-full"
      >
        <.input
          field={@step_2_form_proposal[:proposal_title]}
          type="text"
          label="Título propuesta"
          required
        />
        <.input
          field={@step_2_form_proposal[:proposal_description]}
          type="textarea"
          label="Descripción propuesta"
          description="Describe como esta propuesta contribuye al objetivo de la unidad donde se aplicará. Debe ser consistente con el poder a utilizar."
          required
        />
        <:actions>
          <.button
            phx-click="step_back"
            phx-value-step="1"
            phx-target={@myself}
            phx-disable-with="..."
            class="w-full"
            type="button"
          >
            Atrás
          </.button>

          <.button phx-disable-with="..." class="w-full">
            Revisar
          </.button>
        </:actions>
      </.simple_form>

      <div :if={@step == 3}>
        <h2>Revisa la propuesta</h2>
         {inspect(@proposal_data)} {inspect(@power_data)}
        <div>
          <.button
            type="button"
            phx-click="step_back"
            phx-value-step="2"
            phx-target={@myself}
            phx-disable-with="..."
            class="w-full"
          >
            Atrás
          </.button>

          <.button
            phx-click="step_2_submit"
            phx-target={@myself}
            phx-disable-with="..."
            class="w-full"
          >
            Finalizar
          </.button>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("step_0_validate", %{"proposal" => proposal_params}, socket) do
    proposal_changeset =
      proposal_params
      |> AuroraGov.Command.CreateProposal.handle_validate_step(0)
      |> Map.put(:action, :validate)

    socket =
      socket
      |> assign(step_0_form_proposal: to_form(proposal_changeset, as: "proposal"))
      |> then(fn socket ->
        proposal_power = Map.get(proposal_params, "proposal_power")
        proposal_ou_end = Map.get(proposal_params, "proposal_ou_end")

        if proposal_power && proposal_ou_end do
          socket
          |> assign(:step_0_ou_power_detail, AsyncResult.loading())
          |> start_async(:load_power_detail, fn ->
            :timer.sleep(1000)
            AuroraGov.Context.PowerContext.get_ou_power(proposal_ou_end, proposal_power)
          end)
        else
          socket
          |> assign(:step_0_ou_power_detail, nil)
        end
      end)

    # |> start_async(:load_power_detail, fn ->
    #   AuroraGov.Context.PowerContext.get_power_consensus_by_ou(ou_id, power_id)
    # end)

    {:noreply, socket}
  end

  @impl true
  def handle_event("step_0_next", %{"proposal" => proposal_params}, socket) do
    proposal_changeset =
      proposal_params
      |> AuroraGov.Command.CreateProposal.handle_validate_step(0)
      |> Map.put(:action, :validate)

    socket =
      socket
      |> assign(step_0_form_proposal: to_form(proposal_changeset, as: "proposal"))
      |> then(fn socket ->
        if proposal_changeset.valid? do
          socket
          |> assign(proposal_data: proposal_changeset.changes)
          |> assign_new(:step_1_form_power, fn ->
            proposal_power = proposal_changeset.changes.proposal_power
            command_module = AuroraGov.CommandUtils.find_command_by_id(proposal_power)

            power_changeset = command_module.new(%{})

            to_form(power_changeset, as: "power")
          end)
          |> assign(step: 1)
        else
          socket
        end
      end)

    {:noreply, socket}
  end

  @impl true
  def handle_event("step_back", %{"step" => step}, socket) do
    socket =
      socket
      |> assign(step: String.to_integer(step))

    {:noreply, socket}
  end

  @impl true
  def handle_event("step_1_validate", %{"power" => power_params}, socket) do
    command_module =
      AuroraGov.CommandUtils.find_command_by_id(socket.assigns.proposal_data.proposal_power)

    power_changeset =
      power_params
      |> command_module.new()
      |> Map.put(:action, :validate)

    socket =
      socket
      |> assign(step_1_form_power: to_form(power_changeset, as: "power"))

    {:noreply, socket}
  end

  @impl true
  def handle_event("step_1_next", %{"power" => power_params}, socket) do
    command_module =
      AuroraGov.CommandUtils.find_command_by_id(socket.assigns.proposal_data.proposal_power)

    power_changeset =
      power_params
      |> command_module.new()
      |> Map.put(:action, :validate)

    socket =
      socket
      |> assign(step_1_form_power: to_form(power_changeset, as: "power"))
      |> then(fn socket ->
        if power_changeset.valid? do
          socket
          |> assign(power_data: power_changeset.changes)
          |> assign_new(:step_2_form_proposal, fn ->
            AuroraGov.Command.CreateProposal.handle_validate_step(%{}, 1)
          end)
          |> assign(step: 2)
        else
          socket
        end
      end)

    {:noreply, socket}
  end

  @impl true
  def handle_event("step_2_validate", %{"proposal" => proposal_params}, socket) do
    proposal_changeset =
      proposal_params
      |> AuroraGov.Command.CreateProposal.handle_validate_step(1)
      |> Map.put(:action, :validate)

    socket =
      socket
      |> assign(step_2_form_proposal: to_form(proposal_changeset, as: "proposal"))

    {:noreply, socket}
  end

  @impl true
  def handle_event("step_2_next", %{"proposal" => proposal_params}, socket) do
    proposal_changeset =
      proposal_params
      |> AuroraGov.Command.CreateProposal.handle_validate_step(1)
      |> Map.put(:action, :validate)

    socket =
      socket
      |> assign(step_2_form_proposal: to_form(proposal_changeset, as: "proposal"))
      |> then(fn socket ->
        if proposal_changeset.valid? do
          socket
          |> assign(
            proposal_data: Map.merge(socket.assigns.proposal_data, proposal_changeset.changes)
          )
          |> assign(step: 3)
        else
          socket
        end
      end)

    {:noreply, socket}
  end

  @impl true
  def handle_event("step_2_submit", _params, socket) do
    IO.inspect(socket.assigns.proposal_data, label: "Proposal Data")
    IO.inspect(socket.assigns.power_data, label: "Power Data")

    {:noreply, socket}
  end

  @impl true
  def handle_async(:load_power_detail, {:ok, ou_power_detail}, socket) do
    socket =
      socket
      |> assign(:step_0_ou_power_detail, AsyncResult.ok(ou_power_detail))

    {:noreply, socket}
  end

  @impl true
  def handle_async(:load_data, {:ok, ou_tree}, socket) do
    %{ou_tree: ou_tree_async} = socket.assigns
    {:noreply, assign(socket, :ou_tree, AsyncResult.ok(ou_tree_async, ou_tree))}
  end
end
