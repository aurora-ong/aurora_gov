defmodule AuroraGovWeb.PanelEventRouter do
  require Logger
  import Phoenix.LiveView

  def handle_event({:membership_started, %{person: person, ou: ou} = membership}, socket) do
    socket
    |> put_flash(
      :info,
      "#{person.person_name} (#{person.person_id}) ahora es miembro de #{ou.ou_name} (#{ou.ou_id})"
    )
  end

  def handle_event({:power_updated, power} = update, socket) do
    IO.inspect(power, label: "Handle")

    send_update(PowerPanelComponent,
      id: "panel-power",
      update: update
    )

    socket
  end

  def handle_event(data, socket) do
    Logger.info("No se encontró ruta para #{data}")
    socket
  end

  # defp maybe_update_members_panel(socket, membership) do
  #   send_update(MembersPanelComponent,
  #     id: "members",
  #     membership: membership
  #   )

  #   socket
  # end

  # defp maybe_update_tree_panel(socket, membership) do
  #   send_update(TreePanelComponent,
  #     id: "tree",
  #     context: membership.ou_id,
  #     ou_tree: AuroraGov.Projector.OU.get_tree_by_context(membership.ou_id)
  #   )

  #   socket
  # end

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
