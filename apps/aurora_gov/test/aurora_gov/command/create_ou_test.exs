defmodule AuroraGov.Command.CreateOUTest do
  use AuroraGov.CommandCase, async: false

  describe "CreateOU command" do
    test "successfully creates a root OU" do
      # Este test sirve para crear una unidad organizativa (OU) principal, o sea la raíz de todo.
      # Mandamos el comando CreateOU con datos de prueba básicos y verificamos que se cree bien en el agregado.
      command = %CreateOU{
        ou_id: "root_ou",
        ou_name: "Root Organizational Unit",
        ou_description: "A top-level organization unit for testing",
        ou_goal: "To verify root OU creation works"
      }

      assert :ok = dispatch_command(command)

      assert_receive_event(AuroraGov, OUCreated, fn event ->
        assert event.ou_id == "root_ou"
        assert event.ou_name == "Root Organizational Unit"
        assert event.ou_description == "A top-level organization unit for testing"
        assert event.ou_goal == "To verify root OU creation works"
      end)

      assert %OU{
               ou_id: "root_ou",
               ou_status: :active,
               ou_membership: %{},
               ou_power: %{},
               ou_power_delegation: %{}
             } = AuroraGov.aggregate_state(OU, "root_ou")
    end

    test "successfully creates a child OU under an active parent" do
      # Aquí primero creamos una OU padre, y luego intentamos crear una OU hija vinculada debajo de ella.
      # Verificamos que se reciban los dos eventos de creación en orden y que la hija quede en estado activo.
      parent_command = %CreateOU{
        ou_id: "parent_ou",
        ou_name: "Parent OU",
        ou_description: "Parent description",
        ou_goal: "Parent goal"
      }
      assert :ok = dispatch_command(parent_command)

      child_command = %CreateOU{
        ou_id: "parent_ou.child_ou",
        ou_name: "Child OU",
        ou_description: "Child description",
        ou_goal: "Child goal"
      }
      assert :ok = dispatch_command(child_command)

      assert_receive_event(
        AuroraGov,
        OUCreated,
        fn event -> event.ou_id == "parent_ou" end,
        fn event ->
          assert event.ou_id == "parent_ou"
        end
      )

      assert_receive_event(
        AuroraGov,
        OUCreated,
        fn event -> event.ou_id == "parent_ou.child_ou" end,
        fn event ->
          assert event.ou_id == "parent_ou.child_ou"
          assert event.ou_name == "Child OU"
        end
      )

      assert %OU{
               ou_id: "parent_ou.child_ou",
               ou_status: :active
             } = AuroraGov.aggregate_state(OU, "parent_ou.child_ou")
    end

    test "fails to create child OU when the parent does not exist" do
      # En este test probamos el caso de error cuando intentamos crear una OU hija pero su padre no existe en el sistema.
      # El despacho del comando debería fallar y devolvernos el error :uo_parent_not_exists.
      child_command = %CreateOU{
        ou_id: "nonexistent_parent.child_ou",
        ou_name: "Child OU",
        ou_description: "Child description",
        ou_goal: "Child goal"
      }

      assert {:error, :uo_parent_not_exists} = dispatch_command(child_command)
    end

    test "fails to create OU if it already exists" do
      # Este test es para asegurarnos de que no se puedan crear dos OUs con el mismo ID (duplicadas).
      # Si intentamos crearla por segunda vez, tiene que fallar obligatoriamente con el error :ou_already_exists.
      command = %CreateOU{
        ou_id: "existing_ou",
        ou_name: "Original OU",
        ou_description: "Original description",
        ou_goal: "Original goal"
      }
      assert :ok = dispatch_command(command)

      duplicate_command = %CreateOU{
        ou_id: "existing_ou",
        ou_name: "Duplicate OU",
        ou_description: "Duplicate description",
        ou_goal: "Duplicate goal"
      }
      assert {:error, :ou_already_exists} = dispatch_command(duplicate_command)
    end
  end
end
