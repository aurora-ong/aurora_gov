defmodule AuroraGov.Web.Live.Proposal.VoteModal do
  use AuroraGov.Web, :live_component
  alias Phoenix.LiveView.AsyncResult
  require Logger

  defmodule Context do
    defstruct proposal: nil, current_vote: nil, form_valid?: false
  end

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:context, AsyncResult.loading())
      |> assign(:changeset, AuroraGov.Command.ApplyProposalVote.new())

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(:app_context, assigns.app_context)
      |> assign(
        form:
          to_form(
            AuroraGov.Command.ApplyProposalVote.new(),
            as: "proposal_vote_update_form"
          )
      )
      |> then(fn socket ->
        person_id =
          assigns.app_context.current_person && assigns.app_context.current_person.person_id

        start_async(socket, :load_data, fn -> load_data(assigns.proposal_id, person_id) end)
      end)

    {:ok, socket}
  end

  defp load_data(proposal_id, person_id) do
    Logger.debug("Cargando VoteModal #{proposal_id}, #{person_id}")

    with %AuroraGov.Projector.Model.Proposal{} = proposal <-
           AuroraGov.Context.ProposalContext.get_proposal_by_id(proposal_id),
         current_vote <-
           person_id &&
             AuroraGov.Context.ProposalContext.get_person_vote_from_proposal(
               proposal,
               person_id
             ) do
      %Context{
        proposal: proposal,
        current_vote: current_vote
      }
    else
      {:error, reason} ->
        {:error, reason}

      error ->
        Logger.error("Error #{inspect(error)}")
        {:error, "unknown error"}
    end
  end

  @impl true
  def handle_async(
        :load_data,
        {:ok, result},
        socket
      ) do
    Logger.debug("Cargando VoteModal handle_async #{inspect(result)}")

    case result do
      %Context{} = context ->
        socket =
          socket
          |> assign(:context, AsyncResult.ok(context))
          |> assign(
            :form,
            %{
              "vote_value" => context.current_vote.vote_value,
              "vote_comment" => "Comentario de prueba"
            }
            |> to_form(as: "proposal_vote_update_form")
          )

        {:noreply, socket}

      {:error, reason} ->
        {:noreply,
         socket
         |> assign(:context, AsyncResult.failed(socket.assigns.context, reason))
         |> put_flash(:error, "Error cargando propuesta")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto my-auto w-max-lg flex flex-col justify-center items-start">
      <.async_result :let={context} assign={@context}>
        <:loading>
          <.loading_spinner size="double_large" />
        </:loading>

        <:failed :let={error}>
          <div class="text-center py-8 flex-1 flex flex-col justify-center items-center">
            <i class="fa-solid fa-exclamation-triangle text-4xl text-gray-300 mb-4"></i>
            <h3 class="text-lg font-medium text-gray-900 mb-2">Error al cargar</h3>

            <p class="text-gray-500">
              No se pudo cargar. <br /> {inspect(error)}
            </p>
          </div>
        </:failed>

        <h2 class="text-2xl font-semibold flex items-center gap-2">
          <i class="fa-solid fa-hand-point-up text-2xl"></i> Votar
        </h2>

        <.form_wrapper
          id="proposal_vote_update_form"
          phx-target={@myself}
          phx-submit="submit"
          phx-change="validate"
          class="w-full"
          for={@form}
        >
          <div class="w-full flex flex-col gap-5">
            <.combobox label="Decisión" field={@form[:vote_value]} size="extra_large">
              <:option value="1">Aprobar</:option>

              <:option value="0">Abstener</:option>

              <:option value="-1">Rechazar</:option>
            </.combobox>

            <.textarea_field
              class="w-full"
              disable_resize
              rows="7"
              field={@form[:vote_comment]}
              label="Argumento"
              placeholder="Argumenta tu decisión de manera clara. Este comentario será público."
            />
            <.button
              phx-disable-with="..."
              class="w-full primary filled"
              disabled={!@changeset.valid?}
            >
              {if context.current_vote.updated_at do
                "Actualizar"
              else
                "Votar"
              end}
            </.button>
          </div>

          <div
            :if={context.current_vote.updated_at}
            class="mt-2 text-xs text-gray-500 flex items-center gap-2"
          >
            <i class="fa-solid fa-calendar-days"></i>
            <span>
              Tu voto fue actualizado hace {Timex.lformat!(
                context.current_vote.updated_at,
                "{relative}",
                "es",
                :relative
              )}
            </span>
          </div>
        </.form_wrapper>
      </.async_result>
    </div>
    """
  end

  @impl true
  def handle_event("submit", %{"proposal_vote_update_form" => params}, socket) do
    IO.inspect("XXX")
    IO.inspect(params)

    vote_params =
      params
      |> Map.put("person_id", socket.assigns.app_context.current_person.person_id)
      |> Map.put("proposal_id", socket.assigns.context.result.proposal.proposal_id)
      |> Map.put("vote_type", "direct")

    socket =
      case AuroraGov.Context.ProposalContext.apply_proposal_vote(vote_params) do
        {:ok, _result} ->
          send(self(), {:close, :app_modal, "proposal_vote_update_modal"})

          socket
          |> put_flash(:info, "Actualizado")

        {:error, %Ecto.Changeset{} = changeset} ->
          IO.inspect(changeset)

          socket
          |> assign(
            form:
              to_form(
                changeset,
                as: "proposal_vote_update_form"
              )
          )
          |> put_flash(:error, "No se pudo actualizar")

        {:error, reason} ->
          send(self(), {:close, :app_modal, "proposal_vote_update_modal"})

          socket
          |> put_flash(:info, "No se pudo actualizar #{reason}")
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "validate",
        %{"proposal_vote_update_form" => params},
        socket
      ) do
    changeset =
      params
      |> Map.put("person_id", socket.assigns.app_context.current_person.person_id)
      |> Map.put("proposal_id", socket.assigns.context.result.proposal.proposal_id)
      |> Map.put("vote_type", "direct")
      |> AuroraGov.Command.ApplyProposalVote.new()
      |> Map.put(:action, :validate)

    IO.inspect(changeset)

    socket =
      socket
      |> assign(:changeset, changeset)
      |> assign(
        :form,
        to_form(
          changeset,
          as: "proposal_vote_update_form"
        )
      )

    {:noreply, socket}
  end
end
