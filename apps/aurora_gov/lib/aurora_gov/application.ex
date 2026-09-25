defmodule AuroraGov.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children =
      [
        AuroraGov.Projector.Repo,
        {DNSCluster, query: Application.get_env(:aurora_gov, :dns_cluster_query) || :ignore},
        {Phoenix.PubSub, name: AuroraGov.PubSub},
        {Finch, name: AuroraGov.Finch},
        AuroraGov,
        AuroraGov.Projector,
        AuroraGov.Blockchain.Projector,
        AuroraGov.ProcessManagers.ProposalExecutor
      ] ++ discord_children()

    Supervisor.start_link(children, strategy: :one_for_one, name: AuroraGov.Supervisor)
  end

  # Devuelve los procesos de Discord que deben iniciarse.
  defp discord_children do
    config = Application.get_env(:aurora_gov, :discord_notifications, [])

    if Keyword.get(config, :enabled, false) do
      [AuroraGov.EventHandler.ProposalDiscordHandler]
    else
      []
    end
  end

end
