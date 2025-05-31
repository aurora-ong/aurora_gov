defmodule AuroraGovWeb.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      AuroraGovWeb.Telemetry,
      # Start a worker by calling: AuroraGovWeb.Worker.start_link(arg)
      # {AuroraGovWeb.Worker, arg},
      # Start to serve requests, typically the last entry
      AuroraGovWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: AuroraGovWeb.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    AuroraGovWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
