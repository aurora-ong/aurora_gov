defmodule AuroraGov.ProcessManagers.MembershipRevocationProcess do
  use Commanded.Event.Handler,
    application: AuroraGov,
    name: "MembershipRevocationProcess",
    consistency: :strong

  alias AuroraGov.Event.MembershipRevoked
  alias AuroraGov.Command.RevokeMembership
  alias AuroraGov.Context.MembershipContext
  require Logger

  # Este handler no mantiene estado persistente, simplemente reacciona y despacha.
  def handle(%MembershipRevoked{ou_id: parent_ou_id, person_id: person_id, reason: reason}, _metadata) do
    # Consultamos el Read Model para encontrar subunidades (excluyendo al padre actual para evitar loops)
    memberships = MembershipContext.list_active_memberships_in_ou_subtree(parent_ou_id, person_id)
    
    child_memberships = Enum.filter(memberships, fn m -> m.ou_id != parent_ou_id end)

    commands = Enum.map(child_memberships, fn m ->
      %RevokeMembership{
        ou_id: m.ou_id,
        person_id: person_id,
        reason: "[Cascada desde #{parent_ou_id}] " <> (reason || "")
      }
    end)

    if commands != [] do
      Logger.info("Propagando revocación de membresía de #{person_id} a #{length(commands)} subunidades desde #{parent_ou_id}")
      
      Enum.each(commands, fn cmd ->
        AuroraGov.dispatch(cmd)
      end)
    end

    :ok
  end
end
