defmodule AuroraDiscord.MixProject do
  use Mix.Project

  def project do
    [
      app: :aurora_discord,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.20",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
  [
    extra_applications: [
      :logger,
      :certifi,
      :gun,
      :inets,
      :jason,
      :mime
    ],
    included_applications: [:nostrum],
    mod: {AuroraDiscord.Application, []}
  ]
end

  # Run "mix help deps" to learn about dependencies.
 defp deps do
  [
    {:aurora_gov, in_umbrella: true},
    {:nostrum, "~> 0.10.4", runtime: false},
    {:ecto_sql, "~> 3.10"},
    {:postgrex, ">= 0.0.0"}
  ]
end
end
