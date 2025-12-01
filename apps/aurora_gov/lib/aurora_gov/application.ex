defmodule AuroraGov.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      AuroraGov.Projector.Repo,
      {DNSCluster, query: Application.get_env(:aurora_gov, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: AuroraGov.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: AuroraGov.Finch},
      # Start a worker by calling: AuroraGov.Worker.start_link(arg)
      # {AuroraGov.Worker, arg}

      AuroraGov,
      AuroraGov.Projector,
      AuroraGov.ProcessManagers.ProposalExecutor
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: AuroraGov.Supervisor)
  end
end
