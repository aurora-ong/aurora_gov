defmodule AuroraGov.Utils do
  def normalize_map(map) when is_map(map) do
    Map.new(map, fn {k, v} -> {to_string(k), v} end)
  end

  def normalize_map(nil), do: %{}
end
