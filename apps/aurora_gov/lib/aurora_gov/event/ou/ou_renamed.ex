defmodule AuroraGov.Event.OURenamed do
  @moduledoc """
  Evento de dominio emitido cuando una unidad organizacional
  cambia su nombre visible.

  El identificador `ou_id` de la unidad permanece inmutable.
  Este evento solamente representa el cambio de `ou_name`.
  """

  @derive Jason.Encoder

  defstruct [
    :ou_id,
    :ou_name
  ]
end
