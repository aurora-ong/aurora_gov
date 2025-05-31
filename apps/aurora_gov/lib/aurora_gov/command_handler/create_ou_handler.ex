defmodule AuroraGov.CommandHandler.CreateOUHandler do
  @behaviour Commanded.Commands.Handler
  alias AuroraGov.Aggregate.OU
  alias AuroraGov.Command.CreateOU
  alias AuroraGov.Event.OUCreated
  alias AuroraGov.Utils.OUTree

  def handle(%OU{ou_id: nil}, %CreateOU{ou_id: ou_id, ou_name: ou_name, ou_goal: ou_goal, ou_description: ou_description}) do
    case OUTree.get_parent!(ou_id) do
      ^ou_id ->
        %OUCreated{ou_id: ou_id, ou_name: ou_name, ou_goal: ou_goal, ou_description: ou_description}
      parent ->
        case AuroraGov.aggregate_state(OU, parent) do
          %OU{ou_status: :active} ->
            %OUCreated{ou_id: ou_id, ou_name: ou_name, ou_goal: ou_goal, ou_description: ou_description}

          %OU{ou_id: nil} ->
            {:error, :uo_parent_not_exists}

          %OU{ou_status: _status} ->
            {:error, :uo_parent_not_active}
        end
    end
  end

  def handle(%OU{} = _aggregate, %CreateOU{}) do
    {:error, :ou_already_exists}
  end
end
