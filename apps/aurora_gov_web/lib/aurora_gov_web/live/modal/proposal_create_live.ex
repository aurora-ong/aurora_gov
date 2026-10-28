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
      |> assign(:delegated_votes_count, 0)
      |> assign(:ou_start_name, "")
      |> assign(:ou_end_name, "")

    {:ok, socket}
  end

  @impl true
  def update(%{info: {select_type, field_name, val}}, socket) when select_type in [:ou_selected, :user_selected, :project_selected, :task_selected, :role_selected, :resource_selected] do
    case socket.assigns.step do
      0 ->
        current_params = socket.assigns.step_0_form.params
        new_params = Map.put(current_params, to_string(field_name), val)

        {:noreply, updated_socket} =
          handle_event("step_0_validate", %{"proposal" => new_params}, socket)

        {:ok, updated_socket}

      1 ->
        current_params = socket.assigns.step_1_form.params
        new_params = Map.put(current_params, to_string(field_name), val)

        {:noreply, updated_socket} =
          handle_event("step_1_validate", %{"power" => new_params}, socket)

        {:ok, updated_socket}

      _ ->
        {:ok, socket}
    end
  end

  @impl true
  def update(assigns, socket) do
    person = assigns.app_context.current_person

    socket =
      socket
      |> assign(:id, assigns.id)
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
    <div id={@id}>
      <.modal
        id={"modal-#{@id}"}
        show
        title="Gobernar"
        title_icon="fa-solid fa-hand"
        size="quadruple_large"
        on_cancel={JS.push("app_modal_close", value: %{modal: @id})}
      >
        <div class="w-full min-w-0 max-w-full flex flex-col justify-start items-stretch">
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
      </.modal>
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
        class="w-full min-w-0 max-w-full"
      >
        <div class="flex w-full min-w-0 flex-col gap-4 items-stretch lg:flex-row lg:items-start">
          <div class="flex w-full min-w-0 flex-col gap-5 lg:w-auto lg:flex-1">
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
          <i class="fa-solid fa-arrow-right text-2xl rotate-90 self-center shrink-0 lg:rotate-0 lg:text-3xl" aria-hidden="true"></i>
          <div class="flex w-full min-w-0 flex-col gap-5 justify-center lg:w-auto lg:flex-1">
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

        <div class="w-full min-w-0 max-w-full py-6">
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
          <%!-- <div :if={@step_0_ou_power_detail}>
            <.async_result :let={ou_power} assign={@step_0_ou_power_detail}>
              <:loading><.loading_spinner size="double_large" /></:loading>

              <div class="mt-5">
                <.live_component
                  ou_power={ou_power}
                  parent_target={@myself}
                />
              </div>
            </.async_result>
          </div> --%>
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
    power_id =
      cond do
        is_map(assigns.proposal_data) ->
          Map.get(assigns.proposal_data, :proposal_power_id) ||
            Map.get(assigns.proposal_data, "proposal_power_id")

        true ->
          nil
      end

    power = if power_id, do: AuroraGov.Context.GovPowerContext.get_gov_power!(power_id), else: nil
    assigns = assign(assigns, :power, power)

    ~H"""
    <div class="w-full space-y-6">
      <div :if={@power} class="p-4 bg-slate-50 border border-slate-200/80 rounded-2xl shadow-sm">
        <div class="flex items-start gap-3.5">
          <div class="w-10 h-10 rounded-xl bg-amber-100/90 border border-amber-200 flex items-center justify-center text-amber-700 shrink-0 mt-0.5">
            <i class="fa-solid fa-bolt text-lg"></i>
          </div>
          <div>
            <h3 class="text-base font-bold text-gray-900 mt-1">
              {@power.name}
            </h3>
            <p class="text-xs text-gray-600 mt-0.5 leading-relaxed">
              {@power.description || "Completa los parámetros requeridos para estructurar esta acción en la propuesta."}
            </p>
          </div>
        </div>
      </div>

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
          app_context={@app_context}
          uploads={assigns[:uploads] || %{}}
          target={@myself}
          command_module={@power.module}
          proposal_params={@proposal_data}
        />
        <:actions>
          <.back_button target={@myself} step={0} />
          <.button phx-disable-with="..." class="w-full">Siguiente</.button>
        </:actions>
      </.simple_form>
    </div>
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
      class="w-full space-y-6"
    >
      <div class="flex items-center justify-between p-3.5 bg-gray-50/80 border border-gray-200/80 rounded-xl text-amber-900 text-xs shadow-sm">

        <button
          type="button"
          phx-click="auto_fill_proposal"
          phx-target={@myself}
          class="inline-flex items-center gap-1.5 px-3 py-1.5 text-xs font-semibold rounded-lg text-amber-800 bg-amber-100 hover:bg-amber-200 border border-amber-300 transition-colors shrink-0 cursor-pointer"
        >
          <i class="fa-solid fa-wand-magic-sparkles text-amber-700"></i>
          Autocompletar propuesta
        </button>
      </div>

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
    <div class="space-y-6 w-full mx-auto">
      <h2 class="text-2xl font-bold text-gray-900">Resumen de la Propuesta</h2>

      <div class="bg-white p-6 rounded-2xl border border-gray-100 shadow-sm space-y-4 w-full">
        <div class="flex flex-wrap items-center gap-2 text-sm text-gray-500">
           <span class="font-medium text-gray-700">Origen:</span>
          <.ou_id_badge id={@proposal_ou_start.ou_id} title={@proposal_ou_start.ou_name} size="sm" />
          <i class="fa-solid fa-arrow-right mx-1 text-gray-300"></i>
          <span class="font-bold text-gray-700">Destino:</span>
           <.ou_id_badge id={@proposal_ou_end.ou_id} title={@proposal_ou_end.ou_name} size="sm" />
        </div>

        <div class="border-t border-gray-100 my-3"></div>

        <div class="flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
          <div class="flex-1 space-y-2">
            <h3 class="text-xl font-bold text-gray-950 leading-tight">{@proposal_data[:proposal_title]}</h3>
            <p class="text-gray-600 text-sm whitespace-pre-line leading-relaxed">{@proposal_data[:proposal_description]}</p>
          </div>

          <.badge
            icon="fa-bolt fa-solid"
            size="md"
            class="bg-amber-50 text-amber-800 border border-amber-200 rounded-xl p-3 shrink-0 h-fit"
          >
            {AuroraGov.Context.GovPowerContext.get_gov_power!(@proposal_data[:proposal_power_id]).name}
          </.badge>
        </div>
      </div>

      <.simple_form
        for={@step_3_form}
        id="proposal_step_3_form"
        phx-submit="step_3_next"
        phx-change="step_3_validate"
        phx-target={@myself}
        class="w-full space-y-6"
      >
        <div class="space-y-4">
          <.input
            type="checkbox"
            field={@step_3_form[:proposal_use_delegated]}
            label="Utilizar poder delegado"
          />

          <%= if Ecto.Changeset.get_field(@step_3_form.source, :proposal_use_delegated) == true do %>
            <div class="bg-indigo-50 border border-indigo-100 rounded-xl p-4 flex gap-3 items-start transition-all">
              <i class="fa-solid fa-users text-indigo-600 text-lg mt-0.5 shrink-0"></i>
              <div>
                <h4 class="font-semibold text-indigo-900 text-sm">Poder delegado activo</h4>
                <p class="text-indigo-700 text-xs mt-1 leading-relaxed">
                  Se sumarán automáticamente <span class="font-bold text-sm bg-indigo-100 px-1.5 py-0.5 rounded text-indigo-900">{@delegated_votes_count}</span> votos delegados para este poder desde la unidad de origen de esta propuesta.
                </p>
              </div>
            </div>
          <% end %>
        </div>

        <:actions>
          <.back_button target={@myself} step={2} />
          <.button
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

        proposal_power = proposal_changeset.changes.proposal_power_id
        command_module =
          proposal_power
          |> AuroraGov.Context.GovPowerContext.get_gov_power!()
          |> then(& &1.module)

        upload_fields = Enum.filter(command_module.field_definitions(), &(&1.form_type == :image_upload))

        socket =
          Enum.reduce(upload_fields, socket, fn field, acc ->
            upload_opts = Keyword.get(field.opts, :upload_options, [accept: ~w(.png .jpg .jpeg), max_entries: 1, auto_upload: true])
            allow_upload(acc, field.name, upload_opts)
          end)

        socket
        |> assign(step: 1)
        |> assign(proposal_data: updated_proposal_data)
        |> assign_new(:step_1_form, fn ->
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
  def handle_event("step_1_validate", params, socket) when not is_map_key(params, "power") do
    handle_event("step_1_validate", %{"power" => %{}}, socket)
  end

  @impl true
  def handle_event("step_1_validate", %{"power" => power_params}, socket) do
    command_module =
      socket.assigns.proposal_data.proposal_power_id
      |> AuroraGov.Context.GovPowerContext.get_gov_power!()
      |> then(& &1.module)

    proposal_context = %{
      origin_ou_id: socket.assigns.proposal_data.proposal_ou_origin || socket.assigns.proposal_data["proposal_ou_origin"],
      end_ou_id: socket.assigns.proposal_data.proposal_ou_end || socket.assigns.proposal_data["proposal_ou_end"],
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
  def handle_event("step_1_next", params, socket) when not is_map_key(params, "power") do
    handle_event("step_1_next", %{"power" => %{}}, socket)
  end

  @impl true
  def handle_event("step_1_next", %{"power" => power_params}, socket) do
    command_module =
      socket.assigns.proposal_data.proposal_power_id
      |> AuroraGov.Context.GovPowerContext.get_gov_power!()
      |> then(& &1.module)

    proposal_context = %{
      origin_ou_id: socket.assigns.proposal_data.proposal_ou_origin || socket.assigns.proposal_data["proposal_ou_origin"],
      end_ou_id: socket.assigns.proposal_data.proposal_ou_end || socket.assigns.proposal_data["proposal_ou_end"],
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
  def handle_event("auto_fill_proposal", _params, socket) do
    command_module =
      socket.assigns.proposal_data.proposal_power_id
      |> AuroraGov.Context.GovPowerContext.get_gov_power!()
      |> then(& &1.module)

    proposal_context = %{
      origin_ou_id: socket.assigns.proposal_data.proposal_ou_origin || socket.assigns.proposal_data["proposal_ou_origin"],
      end_ou_id: socket.assigns.proposal_data.proposal_ou_end || socket.assigns.proposal_data["proposal_ou_end"],
      current_person_id: socket.assigns.app_context.current_person.person_id
    }

    power_data =
      cond do
        socket.assigns[:step_1_form] ->
          socket.assigns.step_1_form.source
          |> Ecto.Changeset.apply_changes()
          |> Map.from_struct()

        socket.assigns[:power_data] ->
          socket.assigns.power_data
          |> command_module.new(context: proposal_context)
          |> Ecto.Changeset.apply_changes()
          |> Map.from_struct()

        true ->
          %{}
      end

    suggestion =
      AuroraGov.Web.Utils.ProposalTemplate.generate_default_proposal(
        socket.assigns.proposal_data.proposal_power_id,
        power_data,
        proposal_context
      )

    current_params =
      if socket.assigns[:step_2_form] do
        socket.assigns.step_2_form.params || %{}
      else
        %{}
      end

    updated_params =
      current_params
      |> Map.put("proposal_title", suggestion.title)
      |> Map.put("proposal_description", suggestion.description)

    new_changeset =
      updated_params
      |> AuroraGov.Command.CreateProposal.handle_validate_step(1)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, step_2_form: to_form(new_changeset, as: "proposal"))}
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
        proposal_data = Map.merge(socket.assigns.proposal_data, proposal_changeset.changes)

        delegated_count =
          AuroraGov.Context.PowerDelegationContext.count_ou_tree_delegated_power(
            proposal_data.proposal_ou_origin,
            proposal_data.proposal_power_id
          )

        proposal_ou_start = AuroraGov.Context.OUContext.get_ou(proposal_data.proposal_ou_origin)
        proposal_ou_end = AuroraGov.Context.OUContext.get_ou(proposal_data.proposal_ou_end)

        socket
        |> assign(proposal_data: proposal_data)
        |> assign(delegated_votes_count: delegated_count)
        |> assign(proposal_ou_start: proposal_ou_start)
        |> assign(proposal_ou_end: proposal_ou_end)
        |> assign(step: 3)
        |> assign_new(:step_3_form, fn ->
          %{}
          |> AuroraGov.Command.CreateProposal.handle_validate_step(2)
          |> to_form(as: "proposal")
        end)
      else
        assign(socket, step_2_form: to_form(proposal_changeset, as: "proposal"))
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("step_3_validate", %{"proposal" => proposal_params}, socket) do
    proposal_changeset =
      proposal_params
      |> AuroraGov.Command.CreateProposal.handle_validate_step(2)
      |> Map.put(:action, :validate)

    IO.inspect(proposal_changeset)

    socket =
      socket
      |> assign(proposal_data: Map.merge(socket.assigns.proposal_data, proposal_changeset.changes))
      |> assign(step_3_form: to_form(proposal_changeset, as: "proposal"))

    {:noreply, socket}
  end

  @impl true
  def handle_event("step_3_next", %{"proposal" => proposal_params}, socket) do
    proposal_changeset =
      proposal_params
      |> AuroraGov.Command.CreateProposal.handle_validate_step(2)
      |> Map.put(:action, :validate)

    socket =
      if proposal_changeset.valid? do
        socket
        |> assign(
          proposal_data: Map.merge(socket.assigns.proposal_data, proposal_changeset.changes)
        )
        |> proposal_submit()
      else
        assign(socket, step_3_form: to_form(proposal_changeset, as: "proposal"))
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

  @impl true
  def handle_event("cancel-upload", %{"ref" => ref, "upload-name" => upload_name}, socket) do
    {:noreply, cancel_upload(socket, String.to_existing_atom(upload_name), ref)}
  end

  defp proposal_submit(socket) do
    command_module =
      socket.assigns.proposal_data.proposal_power_id
      |> AuroraGov.Context.GovPowerContext.get_gov_power!()
      |> then(& &1.module)

    upload_fields = Enum.filter(command_module.field_definitions(), &(&1.form_type == :image_upload))

    # Consume dynamically all uploaded entries from configured fields
    uploaded_files =
      Enum.flat_map(upload_fields, fn field ->
        consume_uploaded_entries(socket, field.name, fn %{path: path}, entry ->
          binary_content = File.read!(path)
          file_hash = :crypto.hash(:sha256, binary_content) |> Base.encode16(case: :lower)

          file_extension = Path.extname(entry.client_name)
          new_filename = "#{Ecto.UUID.generate()}#{file_extension}"

          case AuroraGov.Storage.put_file(binary_content, new_filename, entry.client_type) do
            {:ok, url} -> {:ok, {field.name, url, file_hash}}
            {:error, _} -> {:postpone, "No se pudo guardar el archivo"}
          end
        end)
      end)

    # Re-validate power command injecting the uploads directly via context
    proposal_context = %{
      end_ou_id: socket.assigns.proposal_data["proposal_ou_end"] || socket.assigns.proposal_data[:proposal_ou_end]
    }

    power_changeset =
      socket.assigns.power_data
      |> command_module.new(context: proposal_context, uploads: uploaded_files)

    power_data = Ecto.Changeset.apply_changes(power_changeset) |> Map.from_struct()

    full_params =
      socket.assigns.proposal_data
      |> Map.put(:proposal_power_data, power_data)
      |> Map.put(:proposal_person_id, socket.assigns.app_context.current_person.person_id)

    case AuroraGov.Context.ProposalContext.create_proposal!(full_params) do
      {:ok,
       %AuroraGov.Aggregate.Proposal{
         proposal_id: proposal_id,
         proposal_ou_end_id: proposal_ou_end_id
       }} ->
        query_params = %{context: proposal_ou_end_id}

        socket
        |> put_flash(:info, "Propuesta creada exitosamente")
        |> push_navigate(to: ~p"/app/proposals/#{proposal_id}?#{query_params}")

      {:error, reason} ->
        IO.inspect(reason, label: "Error creando propuesta")
        put_flash(socket, :error, "Error al crear la propuesta. Intenta nuevamente.")
    end
  end
end
