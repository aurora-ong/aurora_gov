defmodule AuroraGov.Command.StartMembershipTest do
  use AuroraGov.CommandCase, async: false

  alias AuroraGov.Command.{RegisterPerson, CreateOU, StartMembership}
  alias AuroraGov.Event.MembershipStarted
  alias AuroraGov.Aggregate.OU

  describe "StartMembership command" do
    setup do
      # En el setup registramos un usuario (Alice) y creamos una OU base (root_ou) para poder hacer los tests de membresía.
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
        ou_description: "Root OU description",
        ou_goal: "Root OU goal"
      }
      assert :ok = dispatch_command(create_ou_cmd)

      :ok
    end

    test "successfully starts membership in a root OU" do
      # Este test verifica que un usuario registrado pueda unirse exitosamente a la OU principal.
      # Debería quedar registrado como miembro con rango "junior" de forma predeterminada.
      command = %StartMembership{
        ou_id: "root_ou",
        person_id: "person_123"
      }

      assert :ok = dispatch_command(command)

      assert_receive_event(AuroraGov, MembershipStarted, fn event ->
        assert event.ou_id == "root_ou"
        assert event.person_id == "person_123"
      end)

      assert %OU{
               ou_id: "root_ou",
               ou_membership: %{
                 "person_123" => %OU.Membership{membership_rank: "junior"}
               }
             } = AuroraGov.aggregate_state(OU, "root_ou")
    end

    test "fails to start membership if the OU does not exist" do
      # Aquí probamos que no se puede iniciar membresía en una OU que no existe en el sistema.
      # Debería arrojarnos un error :ou_not_exists.
      command = %StartMembership{
        ou_id: "nonexistent_ou",
        person_id: "person_123"
      }

      assert {:error, :ou_not_exists} = dispatch_command(command)
    end

    test "fails to start membership if the person is not registered" do
      # Este test asegura que alguien no registrado en la plataforma no se pueda unir a una OU.
      # El comando debe fallar con el error :person_not_exists.
      command = %StartMembership{
        ou_id: "root_ou",
        person_id: "nonexistent_person"
      }

      assert {:error, :person_not_exists} = dispatch_command(command)
    end

    test "fails to start membership if already a member" do
      # Verificamos que si un usuario ya es miembro de una OU, no se pueda volver a unir a la misma.
      # Debe fallar devolviendo el error :membership_already_active.
      command = %StartMembership{
        ou_id: "root_ou",
        person_id: "person_123"
      }
      assert :ok = dispatch_command(command)

      assert {:error, :membership_already_active} = dispatch_command(command)
    end

    ##
    test "handles membership in child OU depending on parent membership" do
      # Este test prueba la regla de negocio de que para unirte a una OU hija, debes ser miembro de la OU padre.
      # Bob no está en root_ou, así que no se puede unir a root_ou.child_ou (falla con :parent_membership_not_found).
      # Pero Alice sí está en root_ou, así que ella sí se puede unir con éxito.
      child_ou_cmd = %CreateOU{
        ou_id: "root_ou.child_ou",
        ou_name: "Child OU",
        ou_description: "Child description",
        ou_goal: "Child goal"
      }
      assert :ok = dispatch_command(child_ou_cmd)

      register_bob = %RegisterPerson{
        person_id: "person_bob",
        person_name: "Bob",
        person_mail: "bob@example.com",
        person_password: "password123"
      }
      assert :ok = dispatch_command(register_bob)

      assert :ok = dispatch_command(%StartMembership{
               ou_id: "root_ou",
               person_id: "person_123"
             })

      bob_child_cmd = %StartMembership{
        ou_id: "root_ou.child_ou",
        person_id: "person_bob"
      }
      assert {:error, :parent_membership_not_found} = dispatch_command(bob_child_cmd)

      alice_child_cmd = %StartMembership{
        ou_id: "root_ou.child_ou",
        person_id: "person_123"
      }
      assert :ok = dispatch_command(alice_child_cmd)

      assert_receive_event(
        AuroraGov,
        MembershipStarted,
        fn event -> event.ou_id == "root_ou.child_ou" and event.person_id == "person_123" end,
        fn event ->
          assert event.ou_id == "root_ou.child_ou"
          assert event.person_id == "person_123"
        end
      )
    end
  end
end
