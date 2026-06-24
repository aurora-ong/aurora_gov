defmodule AuroraGov.CommandHandler.UnassignRoleHandler do
  @behaviour Commanded.Commands.Handler
  alias AuroraGov.Aggregate.OU
  alias AuroraGov.Command.UnassignRole
  alias AuroraGov.Event.OURoleUnassigned

  def handle(%OU{ou_id: nil}, _command), do: {:error, :ou_not_exists}

  def handle(%OU{} = ou, %UnassignRole{ou_id: ou_id, role_id: role_id, person_id: person_id}) do
    cond do
      !Map.has_key?(ou.ou_roles || %{}, role_id) ->
        {:error, :role_not_found}

      !MapSet.member?(ou.ou_roles[role_id].assignments, person_id) ->
        {:error, :person_does_not_have_role}

      true ->
        %OURoleUnassigned{ou_id: ou_id, role_id: role_id, person_id: person_id}
    end
  end
end
