defmodule AuroraGov.CommandHandler.UpdateOUAvatarHandler do
  @behaviour Commanded.Commands.Handler

  alias AuroraGov.Aggregate.OU
  alias AuroraGov.Command.UpdateOUAvatar
  alias AuroraGov.Event.OUAvatarUpdated

  def handle(%OU{ou_id: nil}, %UpdateOUAvatar{}) do
    {:error, :ou_not_exists}
  end

  def handle(
        %OU{ou_status: :active} = _ou,
        %UpdateOUAvatar{
          ou_id: ou_id,
          ou_avatar_url: ou_avatar_url,
          file_hash: file_hash
        }
      ) do
    %OUAvatarUpdated{
      ou_id: ou_id,
      ou_avatar_url: ou_avatar_url,
      file_hash: file_hash
    }
  end

  def handle(_ou, %UpdateOUAvatar{}) do
    {:error, :ou_not_active}
  end
end
