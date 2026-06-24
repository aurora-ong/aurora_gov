defmodule AuroraGov.CommandHandler.CreateRoleHandler do
  @behaviour Commanded.Commands.Handler
  alias AuroraGov.Aggregate.OU
  alias AuroraGov.Command.CreateRole
  alias AuroraGov.Event.OURoleCreated

  def handle(%OU{ou_id: nil}, _command), do: {:error, :ou_not_exists}

  def handle(%OU{} = ou, %CreateRole{
        ou_id: ou_id,
        role_id: role_id,
        role_name: role_name,
        role_description: role_description
      }) do
    if Map.has_key?(ou.ou_roles || %{}, role_id) do
      {:error, :role_already_exists}
    else
      %OURoleCreated{
        ou_id: ou_id,
        role_id: role_id,
        role_name: role_name,
        role_description: role_description
      }
    end
  end
end
