defmodule AuroraGov.Utils.OUTree do
  def is_valid?(_id) do
    # TODO MEJORAR
    true
  end

  def is_root?(id) do
    not String.contains?(id, ".")
  end

  def get_parent!(id) do
    case is_root?(id) do
      false ->
        id

      true ->
        split_string = String.split(id, ".")
        parents = List.delete_at(split_string, length(split_string) - 1)
        Enum.join(parents, ".")
    end
  end

  def get_complex_level(id) do
    Enum.count(String.split(id, "."))
  end
end
