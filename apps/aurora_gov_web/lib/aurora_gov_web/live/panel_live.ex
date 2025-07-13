defmodule AuroraGovWeb.PanelLive do
  use AuroraGovWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(AuroraGov.PubSub, "projector_update")
    end

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
    socket = AuroraGovWeb.PanelEventRouter.handle_event(event, socket)

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
end
