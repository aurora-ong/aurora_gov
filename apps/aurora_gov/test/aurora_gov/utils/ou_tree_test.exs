defmodule AuroraGov.Utils.OUTreeTest do
  use ExUnit.Case, async: true
  alias AuroraGov.Utils.OUTree

  describe "valid_slug?/1" do
    test "retorna true para slugs válidos (letras minúsculas, números y guiones bajos)" do
      assert OUTree.valid_slug?("area") == true
      assert OUTree.valid_slug?("area51") == true
      assert OUTree.valid_slug?("sub_area") == true
    end

    test "retorna false para slugs inválidos (mayúsculas, caracteres especiales, puntos o no-strings)" do
      assert OUTree.valid_slug?("Area") == false
      assert OUTree.valid_slug?("sub-area") == false
      assert OUTree.valid_slug?("sub.area") == false
      assert OUTree.valid_slug?("") == false
      assert OUTree.valid_slug?(nil) == false
      assert OUTree.valid_slug?(123) == false
    end
  end

  describe "id_valid?/1" do
    test "retorna true para identificadores jerárquicos correctos separados por punto" do
      assert OUTree.id_valid?("root") == true
      assert OUTree.id_valid?("root.area.sub_area") == true
    end

    test "retorna false para IDs mal estructurados o que exceden el límite de caracteres" do
      # No puede empezar ni terminar con punto, ni tener puntos consecutivos
      assert OUTree.id_valid?(".root") == false
      assert OUTree.id_valid?("root.") == false
      assert OUTree.id_valid?("root..area") == false
      # No string o nulo
      assert OUTree.id_valid?(nil) == false
      assert OUTree.id_valid?(123) == false

      # Excede el límite de 255 caracteres
      largo_id = String.duplicate("a.", 130) # 260 caracteres
      assert OUTree.id_valid?(largo_id) == false
    end
  end

  describe "get_parent/1" do
    test "retorna el ID del padre cuando tiene ancestros" do
      assert OUTree.get_parent("root.area.sub_area") == "root.area"
      assert OUTree.get_parent("root.area") == "root"
    end

    test "retorna nil si el ID es una raíz (no tiene puntos)" do
      assert OUTree.get_parent("root") == nil
    end
  end

  describe "is_root?/1" do
    test "retorna true si el ID es raíz (no contiene puntos)" do
      assert OUTree.is_root?("root") == true
    end

    test "retorna false si contiene puntos o no es un string" do
      assert OUTree.is_root?("root.area") == false
      assert OUTree.is_root?(nil) == false
    end
  end

  describe "get_complex_level/1" do
    test "retorna el nivel de profundidad según la cantidad de segmentos" do
      assert OUTree.get_complex_level("root") == 1
      assert OUTree.get_complex_level("root.area") == 2
      assert OUTree.get_complex_level("root.area.sub_area") == 3
    end
  end

  describe "ou_tree_list/1" do
    test "genera la lista de ancestros desde la raíz hasta el propio ID" do
      assert OUTree.ou_tree_list("a.b.c") == ["a", "a.b", "a.b.c"]
      assert OUTree.ou_tree_list("root") == ["root"]
    end
  end

  describe "join/2" do
    test "concatena el ID del padre y el del hijo usando un punto" do
      assert OUTree.join("parent", "child") == "parent.child"
    end
  end
end
