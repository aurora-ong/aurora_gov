defmodule AuroraGov.Web.Release do
  @moduledoc """
  Used for executing DB release tasks when run in production without Mix
  installed.
  """
  @app :aurora_gov_web

  def drop do
    load_app()

    config = AuroraGov.EventStore.config()
    :ok = EventStore.Tasks.Drop.exec(config, [])

    for repo <- repos() do
      :ok = repo.__adapter__.storage_down(repo.config())
      :ok = repo.__adapter__.storage_up(repo.config())
    end

    :ok
  end

  def seed do
    load_app()

    seeds_file =
      [:code.priv_dir(@app), "repo", "seeds.exs"]
      |> Path.join()

    if File.exists?(seeds_file) do
      Code.eval_file(seeds_file)
    end

    :ok
  end

  def migrate do
    load_app()

    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  def db_eventstore_init do
    load_app()

    config = AuroraGov.EventStore.config()

    :ok = EventStore.Tasks.Create.exec(config, [])
    :ok = EventStore.Tasks.Init.exec(config, [])
  end

  def rollback(repo, version) do
    load_app()
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  defp repos do
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp load_app do
    Application.load(@app)
    {:ok, _} = Application.ensure_all_started(:postgrex)
    {:ok, _} = Application.ensure_all_started(:ssl)
  end
end
