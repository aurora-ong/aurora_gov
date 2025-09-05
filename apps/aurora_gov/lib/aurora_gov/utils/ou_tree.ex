defmodule AuroraGov.Utils.OUTree do
  def id_valid?(_id) do
    # TODO MEJORAR
    true
  end

  def is_root?(id) do
    is_binary(id) and not String.contains?(id, ".")
  end

  def get_parent!(id) do
    case is_root?(id) do
      true ->
        id

      false ->
        split_string = String.split(id, ".")
        parents = List.delete_at(split_string, length(split_string) - 1)
        Enum.join(parents, ".")
    end
  end

  def get_complex_level(id) do
    Enum.count(String.split(id, "."))
  end

  def ou_tree_list(id) do
    parts = String.split(id, ".")
    Enum.reduce_while(Enum.reverse(0..(length(parts) - 1)), [], fn i, acc ->
      sub_id = Enum.take(parts, i + 1) |> Enum.join(".")
      {:cont, [sub_id | acc]}
    end)
  end
end
