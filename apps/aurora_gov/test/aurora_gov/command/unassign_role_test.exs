defmodule AuroraGov.Command.UnassignRoleTest do
  use AuroraGov.CommandCase, async: false

  alias AuroraGov.Command.{RegisterPerson, CreateOU, StartMembership, CreateRole, AssignRole, UnassignRole}
  alias AuroraGov.Event.OURoleUnassigned
  alias AuroraGov.Aggregate.OU

  describe "UnassignRole command" do
    setup do
      # Registramos a Alice, creamos la OU, iniciamos su membresía
      # y creamos el rol "role_coordinador" para preparar las pruebas.
      register_cmd = %RegisterPerson{
        person_id: "person_123",
        person_name: "Alice",
        person_mail: "alice@example.com",
        person_password: "password123"
      }
      assert :ok = dispatch_command(register_cmd)

      create_ou_cmd = %CreateOU{
        ou_id: "root_ou",
        ou_name: "Root OU",
        ou_description: "Root OU para probar desasignaciones",
        ou_goal: "Probar desasignaciones"
      }
      assert :ok = dispatch_command(create_ou_cmd)

      start_membership_cmd = %StartMembership{
        ou_id: "root_ou",
        person_id: "person_123"
      }
      assert :ok = dispatch_command(start_membership_cmd)

      create_role_cmd = %CreateRole{
        ou_id: "root_ou",
        role_id: "role_coordinador",
        role_name: "Coordinador",
        role_description: "Coordinador de pruebas"
      }
      assert :ok = dispatch_command(create_role_cmd)

      :ok
    end

    test "quita exitosamente un rol asignado a un miembro de la OU" do
      # Primero le asignamos el rol a Alice para poder quitárselo luego.
      assign_cmd = %AssignRole{
        ou_id: "root_ou",
        role_id: "role_coordinador",
        person_id: "person_123"
      }
      assert :ok = dispatch_command(assign_cmd)

      # Ahora ejecutamos el comando para quitarle el rol (UnassignRole)
      command = %UnassignRole{
        ou_id: "root_ou",
        role_id: "role_coordinador",
        person_id: "person_123"
      }

      assert :ok = dispatch_command(command)

      # Esperamos el evento de que el rol fue desasignado
      assert_receive_event(AuroraGov, OURoleUnassigned, fn event ->
        assert event.ou_id == "root_ou"
        assert event.role_id == "role_coordinador"
        assert event.person_id == "person_123"
      end)

      # Verificamos que en el agregado el rol ya no tenga a Alice en sus asignaciones
      assert %OU{
               ou_roles: %{
                 "role_coordinador" => %OU.Role{
                   assignments: assignments
                 }
               }
             } = AuroraGov.aggregate_state(OU, "root_ou")

      refute MapSet.member?(assignments, "person_123")
    end

    test "falla al quitar rol si la OU no existe" do
      # Intentamos desasignar en una OU que no existe y esperamos el error :ou_not_exists.
      command = %UnassignRole{
        ou_id: "no_existe_ou",
        role_id: "role_coordinador",
        person_id: "person_123"
      }

      assert {:error, :ou_not_exists} = dispatch_command(command)
    end

    test "falla al quitar un rol que no existe" do
      # Intentamos quitar un rol inexistente ("role_fantasma") y esperamos el error :role_not_found.
      command = %UnassignRole{
        ou_id: "root_ou",
        role_id: "role_fantasma",
        person_id: "person_123"
      }

      assert {:error, :role_not_found} = dispatch_command(command)
    end

    test "falla al quitar un rol si la persona no lo posee" do
      # Intentamos quitarle el rol a Alice sin habérselo asignado primero,
      # lo cual debería rebotar con el error :person_does_not_have_role.
      command = %UnassignRole{
        ou_id: "root_ou",
        role_id: "role_coordinador",
        person_id: "person_123"
      }

      assert {:error, :person_does_not_have_role} = dispatch_command(command)
    end
  end
end
