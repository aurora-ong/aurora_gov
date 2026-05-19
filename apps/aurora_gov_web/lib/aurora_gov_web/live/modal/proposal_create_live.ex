defmodule AuroraGov.Web.Live.Panel.ProposalCreate do
  use AuroraGov.Web, :live_component
  alias AuroraGov.Command.CreateProposal

  defmodule Context do
    defstruct current_step: 0, current_vote: nil, form_valid?: false
  end

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:step, 0)
      |> assign(:proposal_data, %{})
      |> assign(:power_data, %{})
      |> assign(:step_0_ou_power_detail, nil)

    {:ok, socket}
  end

  @impl true
  def update(%{info: {:ou_selected, field_name, ou_id}}, socket) do
    current_params = socket.assigns.step_0_form.params
    new_params = Map.put(current_params, to_string(field_name), ou_id)

    # Re-validamos
    {:noreply, updated_socket} =
      handle_event("step_0_validate", %{"proposal" => new_params}, socket)

    {:ok, updated_socket}
  end

  @impl true
  def update(assigns, socket) do
    person = assigns.app_context.current_person

    socket =
      socket
      |> assign(:app_context, assigns.app_context)
      |> assign(:proposal_params, assigns.proposal_params)
      |> assign(:power_params, assigns.power_params)
      |> assign_async(:ou_tree, fn ->
        if person && person.person_id do
          case AuroraGov.Context.OUContext.get_ou_tree_with_membership(person.person_id) do
            {:error, reason} -> {:error, reason}
            data -> {:ok, %{ou_tree: data}}
          end
        else
          {:error, :no_auth}
        end
      end)
      |> assign_new(:step_0_form, fn ->
        IO.inspect(assigns[:proposal_params], label: "Initial values")

        form_proposal_params = assigns[:proposal_params] || %{}

        form_proposal_params
        |> AuroraGov.Command.CreateProposal.handle_validate_step(0)
        |> to_form(as: "proposal")
      end)
      |> then(fn socket ->
        initial_values = assigns[:proposal_params] || %{}
        proposal_power_id = Map.get(initial_values, "proposal_power_id", nil)
        proposal_ou_end = Map.get(initial_values, "proposal_ou_end", nil)

        step_0_assign_update_ou_power(socket, proposal_ou_end, proposal_power_id)
      end)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto my-auto w-max-lg flex flex-col justify-center items-start">
      <h1 class="text-4xl text-black mb-5"><i class="fa-solid fa-hand text-3xl mr-3"></i>Gobernar</h1>

      <h2 class="text-xl mb-10">Utiliza este formulario para proponer una decisión.</h2>

      <%= case @step do %>
        <% 0 -> %>
          <.step_0 {assigns} />
        <% 1 -> %>
          <.step_1 {assigns} />
        <% 2 -> %>
          <.step_2 {assigns} />
        <% 3 -> %>
          <.step_3 {assigns} />
      <% end %>
    </div>
    """
  end

  defp step_0(assigns) do
    ~H"""
    <.async_result :let={ou_tree} assign={@ou_tree}>
      <:loading><.loading_spinner size="double_large" /></:loading>

      <:failed :let={error}><.error_state error={error} /></:failed>

      <.simple_form
        for={@step_0_form}
        id="proposal_step_0_form"
        phx-submit="step_0_next"
        phx-change="step_0_validate"
        phx-target={@myself}
        class="w-full"
      >
        <div class="flex flex-row gap-4 justify-between items-start flex-nowrap">
          <div class="flex flex-col gap-5 basis-1/2">
            <.live_component
              module={AuroraGov.Web.OUSelectorComponent}
              parent_module={__MODULE__}
              parent_id="modal-proposal_create"
              id="proposal_ou_origin"
              field={@step_0_form[:proposal_ou_origin]}
              label="Unidad Origen"
              ou_tree={ou_tree}
              only_if_member?={true}
              current_person_id={@app_context.current_person.person_id}
              description="Debes pertenecer a esta unidad."
              phx-target={@myself}
            />
          </div>
           <i class="fa-solid fa-arrow-right text-6xl mx-10 self-center"></i>
          <div class="flex flex-col basis-1/2 gap-5 justify-center">
            <.live_component
              module={AuroraGov.Web.OUSelectorComponent}
              parent_module={__MODULE__}
              parent_id="modal-proposal_create"
              id="proposal_ou_end"
              field={@step_0_form[:proposal_ou_end]}
              label="Unidad Destino"
              ou_tree={ou_tree}
              only_if_member?={false}
              current_person_id={@app_context.current_person.person_id}
              description="Unidad donde se ejecutará la acción."
            />
          </div>
        </div>

        <div class="py-6">
          <.combobox
            searchable
            label="Acción"
            field={@step_0_form[:proposal_power_id]}
            size="extra_large"
            options={
              [nil] ++
                (AuroraGov.Context.GovPowerContext.list_gov_power() |> Enum.map(&{&1.name, &1.id}))
            }
            search_placeholder="Buscar poder"
          />
          <div :if={@step_0_ou_power_detail}>
            <.async_result :let={ou_power} assign={@step_0_ou_power_detail}>
              <:loading><.loading_spinner size="double_large" /></:loading>

              <div class="mt-5">
                <.live_component
                  module={AuroraGov.Web.Components.Power.PowerCardComponent}
                  id="power-card"
                  show_actions={false}
                  power_id={@step_0_form[:proposal_power_id].value}
                  power_info={
                    AuroraGov.Context.GovPowerContext.get_gov_power!(
                      @step_0_form[:proposal_power_id].value
                    )
                  }
                  ou_power={ou_power}
                  parent_target={@myself}
                />
              </div>
            </.async_result>
          </div>
        </div>

        <:actions>
          <.button phx-disable-with="..." class="w-full primary filled">
            Siguiente <span aria-hidden="true">→</span>
          </.button>
        </:actions>
      </.simple_form>
    </.async_result>
    """
  end

  defp step_1(assigns) do
    ~H"""
    <.simple_form
      for={@step_1_form}
      id="proposal_step_1_form"
      phx-submit="step_1_next"
      phx-change="step_1_validate"
      phx-target={@myself}
      class="w-full"
    >
      <.live_component
        module={AuroraGov.Web.DynamicCommandFormComponent}
        id="proposal-power_form"
        form={@step_1_form}
        command_module={
          @proposal_data.proposal_power_id
          |> AuroraGov.Context.GovPowerContext.get_gov_power!()
          |> then(& &1.module)
        }
      />
      <:actions>
        <.back_button target={@myself} step={0} />
        <.button phx-disable-with="..." class="w-full">Siguiente</.button>
      </:actions>
    </.simple_form>
    """
  end

  defp step_2(assigns) do
    ~H"""
    <.simple_form
      for={@step_2_form}
      id="proposal_step_2_form"
      phx-submit="step_2_next"
      phx-change="step_2_validate"
      phx-target={@myself}
      class="w-full space-y-8"
    >
      <.input field={@step_2_form[:proposal_title]} type="text" label="Título propuesta" />
      <.input
        field={@step_2_form[:proposal_description]}
        type="textarea"
        label="Descripción propuesta"
        description="Justifica tu propuesta."
      />
      <:actions>
        <.back_button target={@myself} step={1} />
        <.button phx-disable-with="..." class="w-full">Revisar</.button>
      </:actions>
    </.simple_form>
    """
  end

  defp step_3(assigns) do
    ~H"""
    <div class="space-y-6 w-full">
      <h2 class="text-2xl font-bold">Resumen de la Propuesta</h2>

      <div class="bg-gray-50 p-4 rounded border">
        <div class="flex-row flex">
          <%!-- <%= if proposal.proposal_ou_start_id != proposal.proposal_ou_end_id do %>
            <.ou_id_badge
              ou_id={proposal.proposal_ou_start_id}
              ou_name={proposal.proposal_ou_start.ou_name}
              size="sm"
            />
            <span class="mx-2 text-gray-400 flex items-center">
              <i class="fa fa-arrow-right"></i>
            </span>
            <.ou_id_badge
              ou_id={proposal.proposal_ou_end_id}
              ou_name={proposal.proposal_ou_end.ou_name}
              size="sm"
            />
          <% else %>
            <.ou_id_badge
              ou_id={proposal.proposal_ou_end_id}
              ou_name={proposal.proposal_ou_end.ou_name}
              size="sm"
            />
          <% end %> --%>
        </div>
         <hr />
        <div class="flex flex-row items-center">
          <div class="flex grow flex-col">
            {@proposal_data[:proposal_ou_start]}
            <h3 class="font-bold">{@proposal_data[:proposal_title]}</h3>

            <p class="text-gray-600">{@proposal_data[:proposal_description]}</p>
          </div>

          <.badge
            icon="fa-bolt fa-solid"
            size="sm"
            class="hover:bg-gray-100 border border-gray-300 rounded-full p-2 py-3 cursor-pointer h-fit"
          >
            {@proposal_data[:proposal_power_id]}
          </.badge>
        </div>
      </div>

      <.simple_form
        for={@step_2_form}
        id="proposal_step_2_form"
        phx-submit="step_2_next"
        phx-change="step_2_validate"
        phx-target={@myself}
        class="w-full space-y-8"
      >
        <.toggle_field
          name="b"
          label="Utilizar poder delegado"
          checked={false}
          color="primary"
          phx-debounce="300"
        />
        <:actions>
          <.back_button target={@myself} step={2} />
          <.button
            phx-click="proposal_submit"
            phx-target={@myself}
            phx-disable-with="Publicando..."
            class="w-full primary filled"
          >
            Publicar
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  defp error_state(assigns) do
    ~H"""
    <div class="w-full flex flex-col items-center justify-center gap-4 p-6">
      <div class="mb-3">
        <i class={"fa-solid text-5xl text-aurora_orange " <>
          (case @error do
          {:error, :no_auth} -> "fa-user-slash"

             _ -> "fa-circle-exclamation text-gray-500"
           end)}>
        </i>
      </div>

      <div class="text-center">
        <h3 class="text-xl font-semibold">
          {case @error do
            {:error, :no_auth} -> "Inicia sesión para continuar"
            _ -> "Error al cargar"
          end}
        </h3>

        <p class="mt-2 text-sm text-gray-600">
          {case @error do
            {:error, :no_auth} ->
              ""

            error ->
              "Intenta de nuevo más tarde. Código del error #{inspect(error)}"
          end}
        </p>
      </div>

      <%= case @error do %>
        <% {:error, :no_auth} -> %>
          <a href="/persons/log_in" class="primary filled mt-5">Iniciar sesión</a>
        <% _ -> %>
          <.button
            phx-click="app_modal_close"
            phx-value-modal="power-sensibility-modal"
            class="primary filled mt-5"
          >
            Aceptar
          </.button>
      <% end %>
    </div>
    """
  end

  defp back_button(assigns) do
    ~H"""
    <.button
      type="button"
      phx-click="step_back"
      phx-value-step={@step}
      phx-target={@target}
      class="w-full variant-outline"
    >
      Atrás
    </.button>
    """
  end

  defp validate_required_rank(changeset, ou_tree) do
    changeset
    |> Ecto.Changeset.validate_change(:proposal_ou_origin, fn :proposal_ou_origin,
                                                              proposal_ou_origin ->
      ou_membership = Enum.find(ou_tree, fn ou -> ou.ou_id == proposal_ou_origin end)
      IO.inspect(ou_membership)
      valid_ranks = [:regular, :senior]

      if ou_membership.membership_rank in valid_ranks do
        []
      else
        [
          proposal_ou_origin: "Rango insuficiente para levantar propuestas."
        ]
      end
    end)
  end

  defp step_0_assign_update_ou_power(socket, proposal_ou_end, proposal_power_id) do
    if proposal_power_id not in [nil, ""] && proposal_ou_end not in [nil, ""] do
      socket
      |> assign(step_0_ou_power_detail: nil)
      |> assign_async(:step_0_ou_power_detail, fn ->
        {:ok,
         %{
           step_0_ou_power_detail:
             AuroraGov.Context.OuPowerContext.get_ou_power(
               proposal_ou_end,
               proposal_power_id
             )
         }}
      end)
    else
      assign(socket, step_0_ou_power_detail: nil)
    end
  end

  @impl true
  def handle_event("step_0_validate", %{"proposal" => params}, socket) do
    changeset =
      params
      |> CreateProposal.handle_validate_step(0)
      |> validate_required_rank(socket.assigns.ou_tree.result)
      |> Map.put(:action, :validate)

    proposal_power_id = Map.get(params, "proposal_power_id")
    proposal_ou_end = Map.get(params, "proposal_ou_end")

    socket = step_0_assign_update_ou_power(socket, proposal_ou_end, proposal_power_id)

    {:noreply, assign(socket, step_0_form: to_form(changeset, as: "proposal"))}
  end

  @impl true
  def handle_event("step_0_next", %{"proposal" => proposal_params}, socket) do
    proposal_changeset =
      proposal_params
      |> AuroraGov.Command.CreateProposal.handle_validate_step(0)
      |> validate_required_rank(socket.assigns.ou_tree.result)

    socket =
      if proposal_changeset.valid? do
        updated_proposal_data =
          Map.merge(socket.assigns.proposal_data, proposal_changeset.changes)

        socket
        |> assign(step: 1)
        |> assign(proposal_data: updated_proposal_data)
        |> assign_new(:step_1_form, fn ->
          proposal_power = proposal_changeset.changes.proposal_power_id

          command_module =
            proposal_power
            |> AuroraGov.Context.GovPowerContext.get_gov_power!()
            |> then(& &1.module)

          power_changeset =
            command_module.new(socket.assigns.power_params || %{})

          to_form(power_changeset, as: "power")
        end)
      else
        proposal_changeset = Map.put(proposal_changeset, :action, :validate)
        assign(socket, step_0_form: to_form(proposal_changeset, as: "proposal"))
      end

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
      socket.assigns.proposal_data.proposal_power_id
      |> AuroraGov.Context.GovPowerContext.get_gov_power!()
      |> then(& &1.module)

    proposal_context = %{
      origin_ou_id: socket.assigns.app_context.current_ou_id,
      end_ou_id: socket.assigns.app_context.current_ou_id,
      current_person_id: socket.assigns.app_context.current_person.person_id
    }

    power_changeset =
      power_params
      |> command_module.new(context: proposal_context)
      |> Map.put(:action, :validate)

    socket =
      socket
      |> assign(step_1_form: to_form(power_changeset, as: "power"))

    {:noreply, socket}
  end

  @impl true
  def handle_event("step_1_next", %{"power" => power_params}, socket) do
    command_module =
      socket.assigns.proposal_data.proposal_power_id
      |> AuroraGov.Context.GovPowerContext.get_gov_power!()
      |> then(& &1.module)

    proposal_context = %{
      origin_ou_id: socket.assigns.app_context.current_ou_id,
      end_ou_id: socket.assigns.app_context.current_ou_id,
      current_person_id: socket.assigns.app_context.current_person.person_id
    }

    power_changeset =
      power_params
      |> command_module.new(context: proposal_context)
      |> Map.put(:action, :validate)

    socket =
      if power_changeset.valid? do
        socket
        |> assign(power_data: power_changeset.changes)
        |> assign_new(:step_2_form, fn ->
          form_proposal_params = socket.assigns[:proposal_params] || %{}

          form_proposal_params
          |> AuroraGov.Command.CreateProposal.handle_validate_step(1)
          |> to_form(as: "proposal")
        end)
        |> assign(step: 2)
      else
        assign(socket, step_1_form: to_form(power_changeset, as: "power"))
      end

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
      |> assign(step_2_form: to_form(proposal_changeset, as: "proposal"))

    {:noreply, socket}
  end

  @impl true
  def handle_event("step_2_next", %{"proposal" => proposal_params}, socket) do
    proposal_changeset =
      proposal_params
      |> AuroraGov.Command.CreateProposal.handle_validate_step(1)
      |> Map.put(:action, :validate)

    socket =
      if proposal_changeset.valid? do
        socket
        |> assign(
          proposal_data: Map.merge(socket.assigns.proposal_data, proposal_changeset.changes)
        )
        |> assign(step: 3)
      else
        assign(socket, step_2_form: to_form(proposal_changeset, as: "proposal"))
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("proposal_submit", _params, socket) do
    full_params =
      socket.assigns.proposal_data
      |> Map.put(:proposal_power_data, socket.assigns.power_data)
      |> Map.put(:proposal_person_id, socket.assigns.app_context.current_person.person_id)

    case AuroraGov.Context.ProposalContext.create_proposal!(full_params) do
      {:ok,
       %AuroraGov.Aggregate.Proposal{
         proposal_id: proposal_id,
         proposal_ou_end_id: proposal_ou_end_id
       }} ->
        query_params = %{context: proposal_ou_end_id}

        {:noreply,
         socket
         |> put_flash(:info, "Propuesta creada exitosamente")
         |> push_navigate(to: ~p"/app/proposals/#{proposal_id}?#{query_params}")}

      {:error, reason} ->
        IO.inspect(reason, label: "Error creando propuesta")
        {:noreply, put_flash(socket, :error, "Error al crear la propuesta. Intenta nuevamente.")}
    end
  end
end
