defmodule AuroraGov.Command.ArchiveRoleTest do
  use AuroraGov.CommandCase, async: false

  alias AuroraGov.Command.{RegisterPerson, CreateOU, StartMembership, CreateRole, AssignRole, ArchiveRole}
  alias AuroraGov.Event.OURoleArchived
  alias AuroraGov.Aggregate.OU

  describe "ArchiveRole command" do
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
        ou_description: "Root OU para probar archivados",
        ou_goal: "Probar archivados"
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

    test "archiva exitosamente un rol que no tiene personas asignadas" do
      # Este test verifica el camino feliz para archivar un rol que está vacío.
      command = %ArchiveRole{
        ou_id: "root_ou",
        role_id: "role_coordinador"
      }

      assert :ok = dispatch_command(command)

      # Esperamos el evento de archivado
      assert_receive_event(AuroraGov, OURoleArchived, fn event ->
        assert event.ou_id == "root_ou"
        assert event.role_id == "role_coordinador"
      end)

      # Y revisamos que en el agregado de la OU el rol figure con estado :archived
      assert %OU{
               ou_roles: %{
                 "role_coordinador" => %OU.Role{
                   status: :archived
                 }
               }
             } = AuroraGov.aggregate_state(OU, "root_ou")
    end

    test "falla al archivar si la OU no existe" do
      # Intentamos archivar en una OU inexistente y debe dar el error :ou_not_exists.
      command = %ArchiveRole{
        ou_id: "no_existe_ou",
        role_id: "role_coordinador"
      }

      assert {:error, :ou_not_exists} = dispatch_command(command)
    end

    test "falla al archivar si el rol no existe" do
      # Intentamos archivar un rol que no existe ("role_fantasma") y debe dar el error :role_not_found.
      command = %ArchiveRole{
        ou_id: "root_ou",
        role_id: "role_fantasma"
      }

      assert {:error, :role_not_found} = dispatch_command(command)
    end

    test "falla al archivar si el rol ya está archivado" do
      # Archivamos el rol por primera vez.
      command = %ArchiveRole{
        ou_id: "root_ou",
        role_id: "role_coordinador"
      }
      assert :ok = dispatch_command(command)

      # Intentamos archivarlo por segunda vez y debe dar error :role_already_archived.
      assert {:error, :role_already_archived} = dispatch_command(command)
    end

    test "falla al archivar si el rol tiene personas asignadas" do
      # Asignamos el rol a Alice primero.
      assign_cmd = %AssignRole{
        ou_id: "root_ou",
        role_id: "role_coordinador",
        person_id: "person_123"
      }
      assert :ok = dispatch_command(assign_cmd)

      # Intentamos archivar el rol, y debería rebotar con :role_has_active_assignments
      # porque un rol con personas asignadas no puede ser archivado por seguridad.
      command = %ArchiveRole{
        ou_id: "root_ou",
        role_id: "role_coordinador"
      }

      assert {:error, :role_has_active_assignments} = dispatch_command(command)
    end
  end
end
