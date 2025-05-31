defmodule AuroraGovWeb.PanelLive do
  use AuroraGovWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:ou_tree, AuroraGov.Projector.OU.get_all_ou())

    {:ok, socket}
  end

  @impl true
  def handle_params(params, uri, socket) do
    socket =
      socket
      |> assign(:context, parse_context(params, socket))
      |> assign(:module, extract_module_from_uri(uri))
      |> assign(:show_ou_select, parse_ou_select(params))
      |> assign(:uri, uri)

    # IO.inspect(socket)

    # socket =
    #   case params["context"] do
    #     nil ->
    #       push_patch(socket, to: "/panel/?context=#{Enum.at(socket.assigns.ou_tree, 0).ou_id}")

    #     context when is_bitstring(context) ->
    #       ou = Enum.find(socket.assigns.ou_tree, nil, fn ou -> ou.ou_id == context end)

    #       if ou != nil do
    #         assign(socket, context: ou)
    #       else
    #         socket
    #         |> put_flash(:error, "No se encontró la unidad organizacional")
    #         |> push_patch(to: "/panel/?context=#{Enum.at(socket.assigns.ou_tree, 0).ou_id}")
    #       end
    #   end

    #   socket =
    #     case params["module"] do
    #       nil ->
    #         push_patch(socket, to: "/panel/?module=inicio")

    #       module when is_bitstring(module) ->

    #         socket
    #         assign(socket, module: module)
    #         |> push_patch(to: "/panel/?context=")

    #         end
    #     end

    {:noreply, socket}
  end

  # defp update_ou_tree() do
  #   {:ok, %{ou_tree: AuroraGov.Projector.OU.get_all_active_ou()}}
  # end

  defp parse_ou_select(params) do
    case params["show-tree"] do
      "true" ->
        true

      _ ->
        false
    end
  end

  defp parse_context(params, socket) do
    case params["context"] do
      context when is_bitstring(context) ->
        context

      _ ->
        get_default_context(socket)
    end
  end

  defp get_default_context(socket) do
    default = Enum.at(socket.assigns.ou_tree, 0).ou_id

    case default do
      default when is_bitstring(default) ->
        default

      _ ->
        socket
        |> put_flash(:error, "No se encontró ninguna unidad organizacional")
        |> push_patch(to: "/")
    end
  end

  defp extract_module_from_uri(uri) do
    module = Enum.at(String.split(Enum.at(String.split(uri, "/"), -1), "?"), 0)

    case module do
      "app" ->
        "home"

      "" ->
        "home"

      _ ->
        module
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
