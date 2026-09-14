defmodule AuroraGov.Event.OUGoalUpdated do
  @moduledoc """
  Evento de dominio emitido cuando se actualiza el objetivo o meta
  de una unidad organizacional.

  El objetivo está compuesto por:

    * `ou_goal` - objetivo principal de la unidad.
  """

  @derive Jason.Encoder

  defstruct [
    :ou_id,
    :ou_goal
  ]
end
