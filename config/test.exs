import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.

# Configure EventStore Database
config :aurora_gov, AuroraGov.EventStore,
  serializer: Commanded.Serialization.JsonSerializer,
  username: "postgres",
  password: "aurora_gov",
  hostname: "localhost",
  database: "aurora_gov_eventstore_test#{System.get_env("MIX_TEST_PARTITION")}",
  stacktrace: true,
  port: 4500,
  show_sensitive_data_on_connection_error: true,
  pool_size: System.schedulers_online() * 2

config :aurora_gov, AuroraGov.Projector.Repo,
  username: "postgres",
  password: "aurora_gov",
  hostname: "localhost",
  database: "aurora_gov_projector_test#{System.get_env("MIX_TEST_PARTITION")}",
  stacktrace: true,
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 1,
  port: 4500

config :aurora_gov, consistency: :strong

config :aurora_gov, AuroraGov,
  event_store: [
    adapter: Commanded.EventStore.Adapters.InMemory,
    serializer: Commanded.Serialization.JsonSerializer
  ]

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :aurora_gov_web, AuroraGovWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "laY/5uB5lN9Y6qW4LM9RfAop/M5g+P4tI0oG4XEgh5VF7RCG0yqLOJNF1APSvniO",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# In test we don't send emails
config :aurora_gov, AuroraGov.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true
