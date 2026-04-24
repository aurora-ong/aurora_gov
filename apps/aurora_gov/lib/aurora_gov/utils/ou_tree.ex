defmodule AuroraGov.Utils.OUTree do
  @moduledoc """
  Utilidades para manipular identificadores jerárquicos de Unidades (dot-notation).
  Ej: "root.area.sub_area"
  """

  # Solo letras minúsculas, números y guiones bajos.
  # No permite puntos consecutivos ni empezar/terminar con punto.
  @slug_regex ~r/^[a-z0-9_]+$/
  @full_id_regex ~r/^[a-z0-9_]+(\.[a-z0-9_]+)*$/
  @max_length 255

  @doc "Valida si un segmento individual (slug) es correcto"
  def valid_slug?(slug) when is_binary(slug) do
    String.match?(slug, @slug_regex)
  end

  def valid_slug?(_), do: false

  @doc "Valida si un ID jerárquico completo es correcto"
  def id_valid?(id) when is_binary(id) do
    String.length(id) <= @max_length and String.match?(id, @full_id_regex)
  end

  def id_valid?(_), do: false

  @doc "Retorna el padre de un ID. Retorna nil si es raíz."
  def get_parent(id) do
    if is_root?(id) do
      nil
    else
      id
      |> String.split(".")
      |> Enum.drop(-1)
      |> Enum.join(".")
    end
  end

  def is_root?(id) do
    is_binary(id) and not String.contains?(id, ".")
  end

  def get_complex_level(id) do
    id
    |> String.split(".")
    |> length()
  end

  @doc """
  Genera la lista de ancestros incluyendo al propio ID.
  Ej: "a.b.c" -> ["a", "a.b", "a.b.c"]
  """
def ou_tree_list(id) do
    id
    |> String.split(".")
    |> Enum.scan(fn component, acc -> "#{acc}.#{component}" end)
  end

  @doc "Concatena un padre y un hijo de forma segura"
  def join(parent_id, slug), do: "#{parent_id}.#{slug}"
end
