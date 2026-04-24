defmodule AuroraGov.Blockchain.Hasher do
  @moduledoc """
  Módulo encargado de generar huellas digitales criptográficas (Hashes)
  para los eventos del sistema.
  """

  @doc """
  Recibe un Struct (evento) y devuelve su Hash SHA256 en formato Hexadecimal.
  """
  def hash_event(event_struct) do
    event_struct
    # 1. Limpieza: Convertir Struct a Mapa simple
    |> Map.from_struct()

    # 2. Sanitización: Eliminar campos internos de Ecto o Elixir que no son datos
    # :__meta__ es metadata de Ecto que cambia si cargas de BD o memoria.
    # :__struct__ es el nombre del módulo.
    |> Map.drop([:__meta__, :__struct__])

    # 3. Serialización Determinista (Canonical JSON)
    # Jason.encode! produce un string JSON.
    # IMPORTANTE: Jason por defecto suele ser consistente, pero para blockchain real
    # a veces se requiere ordenar las llaves manualmente. Para tu caso, Jason basta.
    |> Jason.encode!()

    # 4. Hashing (SHA256)
    # Usamos la librería :crypto de Erlang (altamente optimizada)
    |> hash_string()
  end

  # Función privada para hashear cualquier string
  defp hash_string(data) do
    :crypto.hash(:sha256, data)
    |> Base.encode16(case: :lower) # Retorna ej: "a1b2c3d4..."
  end
end
