defmodule AuroraGov.Command.CreateRoleTest do
  use AuroraGov.CommandCase, async: false

  alias AuroraGov.Command.{CreateOU, CreateRole}
  alias AuroraGov.Event.OURoleCreated
  alias AuroraGov.Aggregate.OU

  describe "CreateRole command" do
    setup do
      # En el setup siempre creamos una unidad organizativa (OU) principal llamada "root_ou"
      # para poder tener una base donde crear nuestros roles en los tests.
      create_ou_cmd = %CreateOU{
        ou_id: "root_ou",
        ou_name: "Root OU",
        ou_description: "Root OU para probar roles",
        ou_goal: "Probar roles"
      }
      assert :ok = dispatch_command(create_ou_cmd)
      :ok
    end

    test "crea exitosamente un rol en una OU activa" do
      # Este test verifica el "camino feliz" para crear un rol (ej. "Coordinador").
      # Mandamos el comando con un ID de rol manual y validamos el evento.
      command = %CreateRole{
        ou_id: "root_ou",
        role_id: "role_coordinador",
        role_name: "Coordinador",
        role_description: "Encargado de coordinar tareas"
      }

      assert :ok = dispatch_command(command)

      # Esperamos el evento de que el rol fue creado
      assert_receive_event(AuroraGov, OURoleCreated, fn event ->
        assert event.ou_id == "root_ou"
        assert event.role_id == "role_coordinador"
        assert event.role_name == "Coordinador"
        assert event.role_description == "Encargado de coordinar tareas"
      end)

      # Y revisamos que el estado del agregado de la OU ahora contenga el rol en estado activo
      assert %OU{
               ou_roles: %{
                 "role_coordinador" => %OU.Role{
                   role_id: "role_coordinador",
                   role_name: "Coordinador",
                   status: :active
                 }
               }
             } = AuroraGov.aggregate_state(OU, "root_ou")
    end

    test "falla al crear un rol si la OU no existe" do
      # Aquí probamos que si intentamos crear un rol en una OU inexistente,
      # el sistema nos tiene que rebotar con un error de que la OU no existe.
      command = %CreateRole{
        ou_id: "no_existe_ou",
        role_id: "role_admin",
        role_name: "Administrador",
        role_description: "Administrador del sistema"
      }

      assert {:error, :ou_not_exists} = dispatch_command(command)
    end

    test "falla al crear un rol si el ID del rol ya existe" do
      # Este test asegura que no podamos duplicar roles con el mismo ID en la misma OU.
      # Creamos el primer rol sin problemas.
      command = %CreateRole{
        ou_id: "root_ou",
        role_id: "role_repetido",
        role_name: "Rol Original",
        role_description: "El primer rol"
      }
      assert :ok = dispatch_command(command)

      # Intentamos crear otro rol con el mismo ID y debería dar error de que ya existe.
      duplicate_command = %CreateRole{
        ou_id: "root_ou",
        role_id: "role_repetido",
        role_name: "Rol Duplicado",
        role_description: "El segundo rol"
      }
      assert {:error, :role_already_exists} = dispatch_command(duplicate_command)
    end
  end
end
