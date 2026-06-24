defmodule AuroraGov.CommandHandler.ArchiveRoleHandler do
  @behaviour Commanded.Commands.Handler
  alias AuroraGov.Aggregate.OU
  alias AuroraGov.Command.ArchiveRole
  alias AuroraGov.Event.OURoleArchived

  def handle(%OU{ou_id: nil}, _command), do: {:error, :ou_not_exists}

  def handle(%OU{} = ou, %ArchiveRole{ou_id: ou_id, role_id: role_id}) do
    cond do
      !Map.has_key?(ou.ou_roles || %{}, role_id) ->
        {:error, :role_not_found}

      ou.ou_roles[role_id].status == :archived ->
        {:error, :role_already_archived}

      MapSet.size(ou.ou_roles[role_id].assignments) > 0 ->
        {:error, :role_has_active_assignments}

      true ->
        %OURoleArchived{ou_id: ou_id, role_id: role_id}
    end
  end
end
