defmodule AuroraGov.Command.PromoteMembershipTest do
  use AuroraGov.CommandCase, async: false

  alias AuroraGov.Command.{RegisterPerson, CreateOU, StartMembership, PromoteMembership}
  alias AuroraGov.Event.MembershipPromoted
  alias AuroraGov.Aggregate.OU

  describe "PromoteMembership command" do
    setup do
      # En el setup registramos un usuario (Alice) y creamos una OU base (root_ou) para que todos los tests tengan datos listos.
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

    test "successfully promotes a member from junior to regular, and then to senior" do
      # Este test prueba el camino feliz para ascender el rango de un miembro de la organización.
      # Iniciamos la membresía de Alice como junior, luego la ascendemos a regular (verificamos el evento y el estado del agregado),
      # luego a senior (verificamos de nuevo), y finalmente validamos que falle con :max_statement_reached si intentamos ir más allá.
      start_membership_cmd = %StartMembership{
        ou_id: "root_ou",
        person_id: "person_123"
      }
      assert :ok = dispatch_command(start_membership_cmd)

      promote_to_regular = %PromoteMembership{
        ou_id: "root_ou",
        person_id: "person_123"
      }
      assert :ok = dispatch_command(promote_to_regular)

      assert_receive_event(AuroraGov, MembershipPromoted, fn event ->
        assert event.ou_id == "root_ou"
        assert event.person_id == "person_123"
        assert event.membership_rank == "regular"
      end)

      assert %OU{
               ou_membership: %{
                 "person_123" => %OU.Membership{membership_rank: "regular"}
               }
             } = AuroraGov.aggregate_state(OU, "root_ou")

      assert :ok = dispatch_command(promote_to_regular)

      assert_receive_event(
        AuroraGov,
        MembershipPromoted,
        fn event -> event.membership_rank == "senior" end,
        fn event ->
          assert event.ou_id == "root_ou"
          assert event.person_id == "person_123"
          assert event.membership_rank == "senior"
        end
      )

      assert %OU{
               ou_membership: %{
                 "person_123" => %OU.Membership{membership_rank: "senior"}
               }
             } = AuroraGov.aggregate_state(OU, "root_ou")

      assert {:error, :max_statement_reached} = dispatch_command(promote_to_regular)
    end

    test "fails to promote if the OU does not exist" do
      # Aquí probamos que si intentamos ascender a alguien en una OU que no existe en el sistema,
      # el comando tiene que fallar con el error :ou_not_exists.
      command = %PromoteMembership{
        ou_id: "nonexistent_ou",
        person_id: "person_123"
      }

      assert {:error, :ou_not_exists} = dispatch_command(command)
    end

    test "fails to promote if membership does not exist" do
      # Este test es para verificar que no podamos ascender a alguien que ni siquiera es miembro de la OU todavía.
      # Debería devolvernos un error de tipo :membership_not_found.
      command = %PromoteMembership{
        ou_id: "root_ou",
        person_id: "person_123"
      }

      assert {:error, :membership_not_found} = dispatch_command(command)
    end
  end
end
