defmodule AuroraGov.CommandHandler.RenameOUHandler do
  @behaviour Commanded.Commands.Handler

  alias AuroraGov.Aggregate.OU
  alias AuroraGov.Command.RenameOU
  alias AuroraGov.Event.OURenamed

  # La OU todavía no existe en EventStore.
  def handle(%OU{ou_id: nil}, %RenameOU{}) do
    {:error, :ou_not_exists}
  end

  # La OU existe y está activa.
  def handle(
        %OU{ou_status: :active} = ou,
        %RenameOU{
          ou_id: ou_id,
          ou_name: ou_name
        }
      ) do
    %OURenamed{
      ou_id: ou_id,
      ou_name: ou_name
    }
  end

  # La OU existe, pero no está activa.
  def handle(_ou, %RenameOU{}) do
    {:error, :ou_not_active}
  end
end
