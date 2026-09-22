defmodule AuroraDiscord.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children =
  if Application.get_env(:aurora_discord, :enabled, false) do
    [
      AuroraDiscord.Repo,
      Nostrum.Application,
      AuroraDiscord.Consumer,
      AuroraDiscord.ChannelSynchronizer,
      AuroraDiscord.EventHandler.GovernanceNotifier
    ]
  else
    []
  end

    opts = [
      strategy: :one_for_one,
      name: AuroraDiscord.Supervisor
    ]

    Supervisor.start_link(children, opts)
  end
end
