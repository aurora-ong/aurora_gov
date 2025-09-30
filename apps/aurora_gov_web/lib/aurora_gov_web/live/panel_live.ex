defmodule AuroraGovWeb.Live.Panel do
  use AuroraGovWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(AuroraGov.PubSub, "projector_update")
    end

    socket =
      assign(socket,
        side_panel_open: false,
        side_panel_component: nil,
        side_panel_assigns: %{}
      )

    {:ok, socket}
  end

  @impl true
  def handle_params(params, uri, socket) do
    socket =
      socket
      |> assign_context(params)
      |> assign(:module, params["module"] || "home")
      |> assign(:tree_modal, false)
      |> assign(:gov_modal, false)
      |> assign(:uri, uri)

    {:noreply, socket}
  end

  defp assign_context(socket, %{"context" => context}) when context != "" do
    assign(socket, :context, context)
  end

  defp assign_context(socket, _params) do
    case (Enum.at(AuroraGov.Context.OUContext.get_ou_tree(), 0) || %{}).ou_id do
      ou_id when is_binary(ou_id) and ou_id != "" ->
        assign(socket, :context, ou_id)

      _ ->
        socket
        |> put_flash(:error, "No se encontró ninguna unidad organizacional")
        |> push_patch(to: "/")
    end
  end

  @impl true
  def handle_info(event, socket) do
    IO.inspect(event, label: "Actualizando PUBSUB Panel Live")
    socket = AuroraGovWeb.Panel.EventRouter.handle_event(event, socket)

    {:noreply, socket}
  end

  @impl true
  def handle_event("open_gov_modal", params, socket) do
    IO.inspect(params, label: "Params")

    socket =
      socket
      |> assign(:gov_modal, true)
      |> assign(:initial_proposal_values, params)

    {:noreply, socket}
  end

  @impl true
  def handle_event("open_tree_modal", params, socket) do
    IO.inspect(params, label: "Params")

    socket =
      socket
      |> assign(:tree_modal, true)

    {:noreply, socket}
  end

  def handle_event("open_side_panel", %{"component" => component, "assigns" => assigns} = _params, socket) do
    # Convertir claves de string a átomos
    atom_assigns = for {k, v} <- assigns, into: %{} do
      {String.to_atom(k), v}
    end

    {:noreply,
     assign(socket,
       side_panel_open: true,
       side_panel_component: String.to_existing_atom(component),
       side_panel_assigns: atom_assigns
     )}
  end

  def handle_event("close_side_panel", _params, socket) do
    {:noreply,
     assign(socket, side_panel_open: false, side_panel_component: nil, side_panel_assigns: %{})}
  end
end
