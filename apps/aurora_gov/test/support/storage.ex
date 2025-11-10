# test/support/storage.ex
defmodule AuroraGov.Storage do
  @doc """
  Clear the event store and read store databases
  """
  def reset! do
    reset_eventstore()
    reset_readstore()
  end

  defp reset_eventstore do
    config = AuroraGov.EventStore.config()

    {:ok, conn} = Postgrex.start_link(config)

    EventStore.Storage.Initializer.reset!(conn, config)
  end

  defp reset_readstore do
    config = Application.get_env(:aurora_gov, AuroraGov.Projector.Repo)

    {:ok, conn} = Postgrex.start_link(config)

    Postgrex.query!(conn, truncate_readstore_tables(), [])
  end

  defp truncate_readstore_tables do
    """
    TRUNCATE TABLE
      person_table,
      auth_table,
      ou_table,
      membership_table,
      power_table,
      ou_power_table,
      proposal_table,
      projection_versions
    RESTART IDENTITY
    CASCADE;
    """
  end
end
