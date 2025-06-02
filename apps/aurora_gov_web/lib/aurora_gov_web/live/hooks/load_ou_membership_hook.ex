defmodule AuroraGovWeb.Hooks.LoadOUMembership do
  use AuroraGovWeb, :live_view

  def on_mount(:default, _params, _session, socket) do
    ou_tree =
      if socket.assigns.current_person == nil do
        AuroraGov.Projector.OU.get_ou_tree_with_membership()
      else
        user_id = socket.assigns.current_person.person_id || nil
        AuroraGov.Projector.OU.get_ou_tree_with_membership(user_id)
      end

    {:cont, assign(socket, current_ou_tree: ou_tree)}
  end
end
