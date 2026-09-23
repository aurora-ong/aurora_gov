defmodule AuroraGov.Test.CommandCase do
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

  setup _tags do
    _ = Application.stop(:aurora_gov)
    AuroraGov.Test.Storage.reset!()
    {:ok, _} = Application.ensure_all_started(:aurora_gov)

    on_exit(fn ->
      :ok = Application.stop(:aurora_gov)
      AuroraGov.Test.Storage.reset!()
    end)

    :ok
  end
end
