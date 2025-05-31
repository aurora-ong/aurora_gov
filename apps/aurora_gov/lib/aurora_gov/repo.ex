defmodule AuroraGov.Projector.Repo do
  use Ecto.Repo,
    otp_app: :aurora_gov,
    adapter: Ecto.Adapters.Postgres
end
