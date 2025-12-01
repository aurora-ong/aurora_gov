defmodule AuroraGovWeb.Live.Panel do
  use AuroraGovWeb, :live_view

  defmodule AppContext do
    defstruct [:current_ou_id, :current_person, :current_module]
  end

  defmodule AppView do
    @enforce_keys [:view_id, :view_module]
    @type t :: %__MODULE__{
            view_id: binary(),
            view_module: atom(),
            view_options: map(),
            view_params: map()
          }

    defstruct view_id: nil, view_module: nil, view_options: %{}, view_params: %{}
  end

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(AuroraGov.PubSub, "projector_update")
    end

    socket =
      assign(socket,
        app_context: %AppContext{current_person: socket.assigns.current_person},
        app_modal: nil,
        app_side_panel: nil
      )

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    current_ou_id = get_current_ou_id(params)

    socket =
      if current_ou_id != nil do
        socket
        |> assign(:app_modal, nil)
        |> assign(:app_context, %{
          socket.assigns.app_context
          | current_module: params["module"] || "home",
            current_ou_id: current_ou_id
        })
      else
        socket
        |> push_patch(to: "/install")
      end

    {:noreply, socket}
  end

  defp get_current_ou_id(%{"context" => context}) when context != "", do: context

  defp get_current_ou_id(_params) do
    case (Enum.at(AuroraGov.Context.OUContext.get_ou_tree(), 0) || %{}).ou_id do
      ou_id when is_binary(ou_id) and ou_id != "" ->
        ou_id

      _ ->
        nil
    end
  end

  @impl true
  def handle_info({:projector_update, event}, socket) do
    IO.inspect(event, label: "Actualizando PUBSUB Panel Live")
    socket = AuroraGovWeb.Panel.EventRouter.ProjectorUpdate.handle_event(event, socket)

    {:noreply, socket}
  end

  @impl true
  def handle_info({:open, view_id, %AppView{} = app_view}, socket) do
    IO.inspect(app_view, label: "Abriendo #{view_id}")

    socket =
      socket
      |> assign(view_id, app_view)

    {:noreply, socket}
  end

  @impl true
  def handle_info({:close, view_id, id}, socket) do
    IO.inspect(id, label: "Cerrando #{view_id}")

    socket =
      socket
      |> assign(view_id, nil)

    {:noreply, socket}
  end

  @impl true
  def handle_info(event, socket) do
    IO.inspect(event, label: "handle_info desconocido")

    {:noreply, socket}
  end

  @impl true
  def handle_event("app_modal_close", %{"modal" => modal_id}, socket) do
    IO.inspect(modal_id, label: "Cerrando modal")
    {:noreply, assign(socket, app_modal: nil)}
  end

  @impl true
  def handle_event("app_side_panel_close", %{"panel" => panel_id}, socket) do
    IO.inspect(panel_id, label: "Cerrando panel")
    {:noreply, assign(socket, app_side_panel: nil)}
  end
end
