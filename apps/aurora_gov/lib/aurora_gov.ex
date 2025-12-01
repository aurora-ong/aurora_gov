defmodule AuroraGov do
  @moduledoc """
  AuroraGov keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """
  use Commanded.Application,
    otp_app: :aurora_gov,
    event_store: [
      adapter: Commanded.EventStore.Adapters.EventStore,
      event_store: AuroraGov.EventStore
    ]

  # pubsub: [
  #   phoenix_pubsub: [
  #     adapter: Phoenix.PubSub.PG2,
  #     pool_size: 1
  #   ]
  # ]

  router(AuroraGov.Router)

end
