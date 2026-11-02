defmodule AuroraGov.Release do
  require Logger

  @moduledoc """
  Used for executing DB release tasks when run in production without Mix
  installed.
  """
  @app :aurora_gov

  def db_setup do
    Logger.info("DB Setup...")
    db_create()
    db_migrate()
    Logger.info("DB Setup completado")

    :ok
  end

  def db_reset do
    Logger.info("DB Reset...")
    db_drop()
    db_create()
    db_migrate()
    Logger.info("DB Reset completado")

    :ok
  end

  def db_seed(seed_name) do
    {:ok, _} = Application.ensure_all_started(:aurora_gov)

    Logger.info("DB Seeds.")

    filename = if String.ends_with?(seed_name, ".exs"), do: seed_name, else: "#{seed_name}.exs"

    Logger.info("Cargando seeds, filename: #{filename}")

    seeds_file = Path.join([:code.priv_dir(@app), "repo", filename])

    if File.exists?(seeds_file) do
      Code.eval_file(seeds_file)
      Logger.info("Seed ejecutado correctamente.")
    else
      Logger.error("Archivo de seed no encontrado: #{seeds_file}")
      raise "Archivo de seed no encontrado: #{seeds_file}"
    end

    :ok
  end

  def db_migrate do
    Logger.info("DB Migrate...")
    {:ok, _} = Application.ensure_all_started(:aurora_gov)

    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  def db_drop do
    load_app()
    Logger.info("DB Drop...")

    for repo <- repos() do
      repo_config = repo.config()
      db_name = Keyword.get(repo_config, :database)
      if db_name, do: terminate_connections(repo_config, db_name)

      case repo.__adapter__().storage_down(repo_config) do
        :ok ->
          Logger.info("Base de datos eliminada para #{inspect(repo)}")

        {:error, :already_down} ->
          Logger.info("La base de datos para #{inspect(repo)} ya estaba eliminada")

        {:error, term} ->
          Logger.error("Error eliminando base de datos para #{inspect(repo)}: #{inspect(term)}")
      end
    end

    config = AuroraGov.EventStore.config()
    es_db = Keyword.get(config, :database)
    if es_db, do: terminate_connections(config, es_db)
    :ok = EventStore.Tasks.Drop.exec(config, [])
  end

  def db_create do
    load_app()

    Logger.info("DB Create...")

    for repo <- repos() do
      case repo.__adapter__().storage_up(repo.config()) do
        :ok ->
          Logger.info("Base de datos creada para #{inspect(repo)}")

        {:error, :already_up} ->
          Logger.info("La base de datos para #{inspect(repo)} ya existe")

        {:error, term} ->
          Logger.error("Error creando base de datos para #{inspect(repo)}: #{inspect(term)}")
      end
    end

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

  defp terminate_connections(config, database) do
    maintenance_config =
      config
      |> Keyword.put(:database, "postgres")
      |> Keyword.delete(:name)
      |> Keyword.put(:pool_size, 1)

    case Postgrex.start_link(maintenance_config) do
      {:ok, pid} ->
        _ = Postgrex.query(pid, "ALTER DATABASE \"#{database}\" WITH ALLOW_CONNECTIONS false;", [])
        _ = Postgrex.query(pid, "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = $1 AND pid <> pg_backend_pid();", [database])
        GenServer.stop(pid)
        :ok

      {:error, reason} ->
        Logger.warning("No se pudieron cerrar conexiones activas para #{database}: #{inspect(reason)}")
        :ok
    end
  rescue
    e ->
      Logger.warning("Excepción cerrando conexiones activas para #{database}: #{inspect(e)}")
      :ok
  end
end
