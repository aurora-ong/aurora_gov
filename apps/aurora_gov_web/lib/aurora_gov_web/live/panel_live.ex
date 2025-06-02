defmodule AuroraGovWeb.PanelLive do
  use AuroraGovWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(params, uri, socket) do
    socket =
      socket
      |> assign_context(params)
      |> assign(:module, params["module"] || "home")
      |> assign(:tree_modal, params["tree-modal"] == "true")
      |> assign(:gov_modal, params["gov-modal"] == "true")
      |> assign(:uri, uri)

    {:noreply, socket}
  end

  defp assign_context(socket, %{"context" => context}) when context != "" do
    assign(socket, :context, context)
  end

  defp assign_context(socket, _params) do
    case get_in(socket.assigns, [:current_ou_tree, Access.at(0), :ou_id]) do
      ou_id when is_binary(ou_id) and ou_id != "" ->
        assign(socket, :context, ou_id)

      _ ->
        socket
        |> put_flash(:error, "No se encontró ninguna unidad organizacional")
        |> push_patch(to: "/")
    end
  end

  @impl true
  def handle_info(msg, socket) do
    IO.inspect(msg, label: "Actualizando PUBSUB Panel Live")

    socket =
      socket
      |> create_notification(msg)

    {:noreply, socket}
  end

  defp create_notification(socket, msg) do
    case msg do
      %{membership_notification: %{person: person, ou: ou}} ->
        put_flash(
          socket,
          :info,
          "#{person.person_name} (#{person.person_id}) ahora es miembro de #{ou.ou_name} (#{ou.ou_id})"
        )

      _ ->
        socket
    end
  end
end
