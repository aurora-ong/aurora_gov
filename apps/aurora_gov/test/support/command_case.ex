defmodule AuroraGov.CommandCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      import Commanded.Assertions.EventAssertions
      alias AuroraGov.Command.CreateOU
      alias AuroraGov.Event.OUCreated
      alias AuroraGov.Aggregate.OU

      def dispatch_command(command) do
        AuroraGov.dispatch(command)
      end
    end
  end

  setup tags do
    :ok = Application.stop(:aurora_gov)
    {:ok, _} = Application.ensure_all_started(:aurora_gov)

    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(AuroraGov.Projector.Repo, shared: not tags[:async])
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)

    :ok
  end
end
