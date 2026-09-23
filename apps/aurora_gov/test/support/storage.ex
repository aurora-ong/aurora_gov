# test/support/storage.ex
defmodule AuroraGov.Test.Storage do
  @doc """
  Clear the event store and read store databases
  """
  def reset! do
    reset_eventstore()
    reset_projector()
  end

  defp reset_eventstore do
    config = AuroraGov.EventStore.config()
    {:ok, conn} = Postgrex.start_link(config)
    EventStore.Storage.Initializer.reset!(conn, config)
    GenServer.stop(conn)
  end

  defp reset_projector do
    config = Application.get_env(:aurora_gov, AuroraGov.Projector.Repo)
    {:ok, conn} = Postgrex.start_link(config)

    %{rows: rows} =
      Postgrex.query!(
        conn,
        "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' AND table_type = 'BASE TABLE' AND table_name != 'schema_migrations'",
        []
      )

    tables = Enum.map(rows, fn [table] -> table end)

    if tables != [] do
      truncate_query = "TRUNCATE TABLE #{Enum.join(tables, ", ")} RESTART IDENTITY CASCADE;"
      Postgrex.query!(conn, truncate_query, [])
    end

    GenServer.stop(conn)
  end
end
