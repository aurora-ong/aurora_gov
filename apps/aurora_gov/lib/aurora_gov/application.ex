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
      ]
      |> filter_test_children()

    Supervisor.start_link(children, strategy: :one_for_one, name: AuroraGov.Supervisor)
  end

  if Mix.env() == :test do
    defp filter_test_children(children) do
      Enum.reject(children, fn
        AuroraGov.Projector -> true
        AuroraGov.Blockchain.Projector -> true
        AuroraGov.ProcessManagers.ProposalExecutor -> true
        _ -> false
      end)
    end
  else
    defp filter_test_children(children), do: children
  end
end
