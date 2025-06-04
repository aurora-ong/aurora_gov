defmodule AuroraGovWeb.GovLiveComponent do
  use AuroraGovWeb, :live_component

  @impl true
  def update(%{info: {:ou_selected, field_name, field_data}}, socket) do
    changeset =
      socket.assigns.form_proposal.source
      |> Ecto.Changeset.change(Map.new() |> Map.put(field_name, field_data))
      |> Map.put(:action, :validate)

    {:ok, assign(socket, form_proposal: to_form(changeset, as: "proposal"))}
  end

  def update(assigns, socket) do
    # Inicializa el formulario si no está presente
    socket =
      socket
      |> assign(assigns)
      |> assign_new(:form_proposal, fn ->
        to_form(AuroraGov.Command.CreateProposal.new(), as: "proposal")
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
        for={@form_proposal}
        id="login_form"
        phx-submit="next"
        phx-change="validate"
        phx-target={@myself}
        class="w-full"
      >
        <%!-- <.input field={@form_proposal[:proposal_title]} type="text" label="Título propuesta" required />
        <.input
          field={@form_proposal[:proposal_description]}
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
              field={@form_proposal[:proposal_ou_origin]}
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
              field={@form_proposal[:proposal_ou_end]}
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
              field={@form_proposal[:proposal_power]}
              type="select"
              label="Poder"
              options={[nil] ++ AuroraGov.CommandUtils.all_proposable_modules_select()}
              description="Selecciona el poder que deseas proponer. Este poder será ejecutado por la unidad destino."
            />
          </div>

          <div class="flex flex-col basis-1/2 gap-5 justify-center px-10">
            <div
              :if={
                @form_proposal[:proposal_power].value != nil and
                  @form_proposal[:proposal_power].value != ""
              }
              class="border border-aurora_orange px-5 py-5 rounded-lg"
            >
              <div>
                <label class="text-sm text-gray-500">
                  Requiere <strong>45%</strong> de aprobación colectiva
                </label>

                <div class="w-full bg-gray-200 rounded-full h-2 mt-1">
                  <div class="bg-blue-600 h-2 rounded-full" style="width: 45%;"></div>
                </div>

                <p class="text-xs text-gray-500 mt-2 flex flex-row items-center">
                  <i class="fa-solid fa-hand mr-2" />Usado 2 veces en los últimos 7 días
                </p>
              </div>
            </div>
          </div>
        </div>

        <.live_component
          :if={
            @form_proposal[:proposal_power].value != nil and
              @form_proposal[:proposal_power].value != ""
          }
          module={AuroraGovWeb.DynamicCommandFormComponent}
          id="proposal-power_form"
          form={@form_power}
          command_module={
            AuroraGov.CommandUtils.find_command_by_id(@form_proposal[:proposal_power].value)
          }
        />
        <:actions>
          <.button phx-disable-with="..." class="w-full">
            Siguiente <span aria-hidden="true">→</span>
          </.button>
        </:actions>
      </.simple_form>

      <.simple_form
        :if={@step == 1}
        for={@form_proposal}
        id="proposal_details_form"
        phx-submit="next"
        phx-change="validate"
        phx-target={@myself}
        class="w-full"
      >
        <.input
          field={@form_proposal[:proposal_title]}
          type="text"
          label="Título propuesta"
          required
        />
        <.input
          field={@form_proposal[:proposal_description]}
          type="textarea"
          label="Descripción propuesta"
          description="Describe como esta propuesta contribuye al objetivo de la unidad donde se aplicará. Debe ser consistente con el poder a utilizar."
          required
        />
        <:actions>
          <.button phx-click="back" phx-target={@myself} phx-disable-with="..." class="w-full">
            Atrás
          </.button>

          <.button phx-disable-with="..." class="w-full">
            Finalizar
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def handle_event("validate", params, socket) do
    proposal_params = Map.get(params, "proposal", %{})
    power_params = Map.get(params, "power", %{})

    proposal_power_old = socket.assigns.form_proposal[:proposal_power].value
    proposal_power_new = proposal_params["proposal_power"]

    form_power =
      cond do
        proposal_power_new in [nil, ""] ->
          nil

        proposal_power_new == proposal_power_old and socket.assigns[:form_power] ->
          command_module = AuroraGov.CommandUtils.find_command_by_id(proposal_power_new)

          power_params
          |> command_module.new()
          |> Map.put(:action, :validate)
          |> then(&to_form(&1, as: "power"))

        true ->
          AuroraGov.CommandUtils.find_command_by_id(proposal_power_new).new(%{})
          |> then(&to_form(&1, as: "power"))
      end

    proposal_changeset =
      proposal_params
      |> AuroraGov.Command.CreateProposal.new()
      |> Map.put(:action, :validate)

    socket =
      socket
      |> assign(form_proposal: to_form(proposal_changeset, as: "proposal"))
      |> assign(form_power: form_power)

    {:noreply, socket}
  end

  @impl true
  def handle_event("next", params, socket) do
    proposal_params = Map.get(params, "proposal", %{})
    power_params = Map.get(params, "power", %{})

    proposal_power_old = socket.assigns.form_proposal[:proposal_power].value
    proposal_power_new = proposal_params["proposal_power"]

    form_power =
      cond do
        proposal_power_new in [nil, ""] ->
          nil

        proposal_power_new == proposal_power_old and socket.assigns[:form_power] ->
          command_module = AuroraGov.CommandUtils.find_command_by_id(proposal_power_new)

          power_params
          |> command_module.new()
          |> Map.put(:action, :validate)
          |> then(&to_form(&1, as: "power"))

        true ->
          AuroraGov.CommandUtils.find_command_by_id(proposal_power_new).new(%{})
          |> then(&to_form(&1, as: "power"))
      end

    proposal_changeset =
      proposal_params
      |> AuroraGov.Command.CreateProposal.new()
      |> Map.put(:action, :validate)

    socket =
      socket
      |> assign(form_proposal: to_form(proposal_changeset, as: "proposal"))
      |> assign(form_power: form_power)
      |> assign(step: 1)

    {:noreply, socket}
  end

  @impl true
  def handle_event("back", _params, socket) do
    socket =
      socket
      |> assign(step: 0)

    {:noreply, socket}
  end
end
