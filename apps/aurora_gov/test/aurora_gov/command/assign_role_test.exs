defmodule AuroraGov.Command.AssignRoleTest do
  use AuroraGov.CommandCase, async: false

  alias AuroraGov.Command.{RegisterPerson, CreateOU, StartMembership, CreateRole, AssignRole, ArchiveRole}
  alias AuroraGov.Event.OURoleAssigned
  alias AuroraGov.Aggregate.OU

  describe "AssignRole command" do
    setup do
      # En el setup registramos a Alice, creamos la OU, iniciamos su membresía
      # y creamos un rol base "role_coordinador" para tener todo listo.
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
        ou_description: "Root OU para probar asignaciones",
        ou_goal: "Probar asignaciones"
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

    test "asigna exitosamente un rol activo a un miembro de la OU" do
      # Este test verifica que Alice sea asignada exitosamente al rol de Coordinador.
      command = %AssignRole{
        ou_id: "root_ou",
        role_id: "role_coordinador",
        person_id: "person_123"
      }

      assert :ok = dispatch_command(command)

      # Esperamos el evento de que el rol fue asignado a Alice
      assert_receive_event(AuroraGov, OURoleAssigned, fn event ->
        assert event.ou_id == "root_ou"
        assert event.role_id == "role_coordinador"
        assert event.person_id == "person_123"
      end)

      # Verificamos que en el agregado el rol ahora tenga la persona en su lista de asignaciones
      assert %OU{
               ou_roles: %{
                 "role_coordinador" => %OU.Role{
                   assignments: assignments
                 }
               }
             } = AuroraGov.aggregate_state(OU, "root_ou")

      assert MapSet.member?(assignments, "person_123")
    end

    test "falla al asignar rol si la OU no existe" do
      # Intentamos asignar el rol en una OU que no existe y esperamos el error :ou_not_exists.
      command = %AssignRole{
        ou_id: "no_existe_ou",
        role_id: "role_coordinador",
        person_id: "person_123"
      }

      assert {:error, :ou_not_exists} = dispatch_command(command)
    end

    test "falla al asignar un rol que no existe" do
      # Intentamos asignar un rol inexistente ("role_fantasma") a Alice y debería dar error :role_not_found.
      command = %AssignRole{
        ou_id: "root_ou",
        role_id: "role_fantasma",
        person_id: "person_123"
      }

      assert {:error, :role_not_found} = dispatch_command(command)
    end

    test "falla al asignar rol si la persona no es miembro de la OU" do
      # Registramos a Bob, pero no lo unimos a la OU, así que no debería poder recibir roles en ella.
      register_bob = %RegisterPerson{
        person_id: "person_bob",
        person_name: "Bob",
        person_mail: "bob@example.com",
        person_password: "password123"
      }
      assert :ok = dispatch_command(register_bob)

      command = %AssignRole{
        ou_id: "root_ou",
        role_id: "role_coordinador",
        person_id: "person_bob"
      }

      assert {:error, :person_not_member} = dispatch_command(command)
    end

    test "falla al asignar un rol que la persona ya posee" do
      # Le asignamos el rol a Alice por primera vez.
      command = %AssignRole{
        ou_id: "root_ou",
        role_id: "role_coordinador",
        person_id: "person_123"
      }
      assert :ok = dispatch_command(command)

      # Intentamos asignárselo de nuevo y tiene que fallar con :person_already_has_role.
      assert {:error, :person_already_has_role} = dispatch_command(command)
    end

    test "falla al asignar un rol que ya está archivado" do
      # Primero archivamos el rol usando el comando ArchiveRole.
      archive_cmd = %ArchiveRole{
        ou_id: "root_ou",
        role_id: "role_coordinador"
      }
      assert :ok = dispatch_command(archive_cmd)

      # Ahora intentamos asignárselo a Alice y debería fallar con :role_archived.
      command = %AssignRole{
        ou_id: "root_ou",
        role_id: "role_coordinador",
        person_id: "person_123"
      }

      assert {:error, :role_archived} = dispatch_command(command)
    end
  end
end
