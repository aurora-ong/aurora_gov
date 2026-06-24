defmodule AuroraGov.CommandHandler.AssignRoleHandler do
  @behaviour Commanded.Commands.Handler
  alias AuroraGov.Aggregate.OU
  alias AuroraGov.Command.AssignRole
  alias AuroraGov.Event.OURoleAssigned

  def handle(%OU{ou_id: nil}, _command), do: {:error, :ou_not_exists}

  def handle(%OU{} = ou, %AssignRole{ou_id: ou_id, role_id: role_id, person_id: person_id}) do
    cond do
      !Map.has_key?(ou.ou_roles || %{}, role_id) ->
        {:error, :role_not_found}

      ou.ou_roles[role_id].status == :archived ->
        {:error, :role_archived}

      !Map.has_key?(ou.ou_membership || %{}, person_id) ->
        {:error, :person_not_member}

      MapSet.member?(ou.ou_roles[role_id].assignments, person_id) ->
        {:error, :person_already_has_role}

      true ->
        %OURoleAssigned{ou_id: ou_id, role_id: role_id, person_id: person_id}
    end
  end
end
