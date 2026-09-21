defmodule AuroraGov.Event.OUAvatarUpdated do
  @derive Jason.Encoder
  defstruct [:ou_id, :ou_avatar_url, :file_hash]
end
