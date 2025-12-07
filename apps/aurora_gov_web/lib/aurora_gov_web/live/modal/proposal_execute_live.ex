defmodule AuroraGovWeb.Live.Proposal.ExecuteModal do
  use AuroraGovWeb, :live_component
  alias Phoenix.LiveView.AsyncResult
  require Logger

  defmodule Context do
    defstruct proposal_id: nil, can_execute?: nil
  end

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:context, AsyncResult.loading())

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(:app_context, assigns.app_context)
      |> start_async(:load_data, fn ->
        load_data(assigns.proposal_id, assigns.app_context.current_person.person_id)
      end)

    {:ok, socket}
  end

  defp load_data(proposal_id, person_id) do
    Logger.debug("Cargando ExecuteModal #{proposal_id}, #{person_id}")

    :timer.sleep(2000)

    %Context{
      can_execute?: true
    }

    with r <-
           AuroraGov.Context.ProposalContext.can_proposal_execute?(proposal_id) do
      %Context{
        proposal_id: proposal_id,
        can_execute?: r
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
    Logger.debug("Cargando ExecuteModal handle_async #{inspect(result)}")

    case result do
      %Context{} = context ->
        socket =
          socket
          |> assign(:context, AsyncResult.ok(context))

        {:noreply, socket}

      {:error, reason} ->
        {:noreply,
         socket
         |> assign(:context, AsyncResult.failed(socket.assigns.context, reason))
         |> put_flash(:error, "Error cargando")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto my-auto w-max-lg flex flex-col justify-center items-start">
      <.async_result :let={context} assign={@context}>
        <:loading>
          <.loading_spinner size="double_large" text="Validando" />
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
          <i class="fa-solid fa-hand-point-up text-2xl"></i> Promulgar
        </h2>

        <h4 class="my-5">
          Hacer en click en promulgar hará esta acción oficial y será notificada publicamente. Esta acción no se puede cancelar.
        </h4>

        <.button
          phx-click="submit"
          phx-target={@myself}
          phx-disable-with="..."
          class="w-full primary filled"
          disabled={!context.can_execute?}
        >
          Promulgar
        </.button>
      </.async_result>
    </div>
    """
  end

  @impl true
  def handle_event("submit", _params, socket) do
    socket =
      case AuroraGov.Context.ProposalContext.consume_proposal(
             socket.assigns.context.result.proposal_id
           ) do
        {:ok, _result} ->
          send(self(), {:close, :app_modal, "proposal_vote_update_modal"})

          socket
          |> put_flash(:success, "Promulgado")

        {:error, reason} ->
          send(self(), {:close, :app_modal, "proposal_vote_update_modal"})

          socket
          |> put_flash(:info, "No se pudo ejecutar #{reason}")
      end

    {:noreply, socket}
  end
end
