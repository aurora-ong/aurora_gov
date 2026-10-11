defmodule AuroraGov.Test.Command.DowngradeMembershipTest do
  use AuroraGov.Test.CommandCase, async: false

  alias AuroraGov.Command.{RegisterPerson, CreateOU, StartMembership, PromoteMembership, DowngradeMembership}
  alias AuroraGov.Event.MembershipDowngraded
  alias AuroraGov.Aggregate.OU

  describe "DowngradeMembership command" do
    setup do
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

      start_membership_cmd = %StartMembership{
        ou_id: "root_ou",
        person_id: "person_123"
      }
      assert :ok = dispatch_command(start_membership_cmd)

      :ok
    end

    test "successfully downgrades a member from senior to regular, and then to junior" do
      # Primero promovemos hasta senior
      assert :ok = dispatch_command(%PromoteMembership{ou_id: "root_ou", person_id: "person_123"})
      assert :ok = dispatch_command(%PromoteMembership{ou_id: "root_ou", person_id: "person_123"})
      
      assert %OU{
               ou_membership: %{
                 "person_123" => %OU.Membership{membership_rank: "senior"}
               }
             } = AuroraGov.aggregate_state(OU, "root_ou")

      # Degradamos a regular
      downgrade_cmd = %DowngradeMembership{
        ou_id: "root_ou",
        person_id: "person_123"
      }
      assert :ok = dispatch_command(downgrade_cmd)

      assert_receive_event(AuroraGov, MembershipDowngraded, fn event ->
        assert event.ou_id == "root_ou"
        assert event.person_id == "person_123"
        assert event.membership_rank == "regular"
      end)

      assert %OU{
               ou_membership: %{
                 "person_123" => %OU.Membership{membership_rank: "regular"}
               }
             } = AuroraGov.aggregate_state(OU, "root_ou")

      # Degradamos a junior
      assert :ok = dispatch_command(downgrade_cmd)

      assert_receive_event(
        AuroraGov,
        MembershipDowngraded,
        fn event -> event.membership_rank == "junior" end,
        fn event ->
          assert event.ou_id == "root_ou"
          assert event.person_id == "person_123"
          assert event.membership_rank == "junior"
        end
      )

      assert %OU{
               ou_membership: %{
                 "person_123" => %OU.Membership{membership_rank: "junior"}
               }
             } = AuroraGov.aggregate_state(OU, "root_ou")

      # Verificamos que falla si ya es junior
      assert {:error, :min_rank_reached} = dispatch_command(downgrade_cmd)
    end

    test "fails to downgrade if the OU does not exist" do
      command = %DowngradeMembership{
        ou_id: "nonexistent_ou",
        person_id: "person_123"
      }

      assert {:error, :ou_not_exists} = dispatch_command(command)
    end

    test "fails to downgrade if membership does not exist" do
      command = %DowngradeMembership{
        ou_id: "root_ou",
        person_id: "unknown_person"
      }

      assert {:error, :membership_not_found} = dispatch_command(command)
    end
  end
end
