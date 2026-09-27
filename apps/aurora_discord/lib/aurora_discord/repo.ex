defmodule AuroraDiscord.Repo do
  @moduledoc """
  Repositorio perteneciente exclusivamente a la integración con Discord.

  Almacena información técnica de la integración, como la asociación
  entre unidades organizacionales de Aurora y canales de Discord.

  No almacena estado del dominio de gobernanza.
  """

  use Ecto.Repo,
    otp_app: :aurora_discord,
    adapter: Ecto.Adapters.Postgres
end
