defmodule AuroraGov.MixProject do
  use Mix.Project

  def project do
    [
      app: :aurora_gov,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {AuroraGov.Application, []},
      extra_applications: [:logger, :runtime_tools, :jason]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:dns_cluster, "~> 0.1.1"},
      {:phoenix_pubsub, "~> 2.1"},
      {:ecto_sql, "~> 3.10"},
      {:postgrex, ">= 0.0.0"},
      {:jason, "~> 1.2"},
      {:swoosh, "~> 1.5"},
      {:finch, "~> 0.13"},
      {:commanded, "~> 1.4.3"},
      {:commanded_eventstore_adapter, "~> 1.4"},
      {:commanded_ecto_projections, "~> 1.4"},
      {:pbkdf2_elixir, "~> 2.0"},
      {:faker, "~> 0.18.0"},
      {:ecto_shortuuid, "~> 0.2"},
      {:commanded_messaging, "~> 0.2.0"},
      {:flop, "~> 0.26.3"},
      {:flop_phoenix, "~> 0.25.3"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "event_store.setup", "projector.setup"],
      "db.drop": ["ecto.drop", "event_store.drop"],
      "db.reset": ["db.drop", "db.setup"],
      "db.setup": ["event_store.setup", "projector.setup", "run #{__DIR__}/priv/repo/seeds.exs"],
      "projector.setup": ["ecto.create", "ecto.migrate"],
      "projector.reset": ["ecto.drop", "projector.setup"],
      "event_store.setup": ["event_store.create", "event_store.init"],
      "event_store.reset": ["event_store.drop", "event_store.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"]
    ]
  end
end
