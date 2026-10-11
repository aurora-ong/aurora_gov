defmodule AuroraGov.Test.Command.RevokeMembershipTest do
  use AuroraGov.Test.CommandCase, async: false

  alias AuroraGov.Command.{RegisterPerson, CreateOU, StartMembership, RevokeMembership}
  alias AuroraGov.Event.MembershipRevoked
  alias AuroraGov.Aggregate.OU

  describe "RevokeMembership command" do
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

      create_child_ou_cmd = %CreateOU{
        ou_id: "root_ou.child1",
        ou_name: "Child 1",
        ou_description: "Child 1 description",
        ou_goal: "Child 1 goal"
      }
      assert :ok = dispatch_command(create_child_ou_cmd)

      :ok
    end

    test "successfully revokes membership from parent and cascades to child OU" do
      # Start membership in both parent and child
      assert :ok = dispatch_command(%StartMembership{ou_id: "root_ou", person_id: "person_123"})
      assert :ok = dispatch_command(%StartMembership{ou_id: "root_ou.child1", person_id: "person_123"})

      # Wait for the read model to be updated by the projector
      # since the ProcessManager needs to read it.
      wait_for_projector("root_ou", "person_123", 2)

      # Revoke membership from parent
      revoke_cmd = %RevokeMembership{
        ou_id: "root_ou",
        person_id: "person_123",
        reason: "Violated rules"
      }
      assert :ok = dispatch_command(revoke_cmd)

      # Wait for the direct MembershipRevoked event on the parent
      assert_receive_event(
        AuroraGov,
        MembershipRevoked,
        fn event -> event.ou_id == "root_ou" end,
        fn event ->
          assert event.ou_id == "root_ou"
          assert event.person_id == "person_123"
        end
      )

      # Check parent aggregate state
      parent_state = AuroraGov.aggregate_state(OU, "root_ou")
      assert map_size(parent_state.ou_membership) == 0

      # Wait for the cascaded MembershipRevoked event on the child
      assert_receive_event(
        AuroraGov,
        MembershipRevoked,
        fn event -> event.ou_id == "root_ou.child1" end,
        fn event ->
          assert event.ou_id == "root_ou.child1"
          assert event.person_id == "person_123"
        end
      )

      # Check child aggregate state
      child_state = AuroraGov.aggregate_state(OU, "root_ou.child1")
      assert map_size(child_state.ou_membership) == 0
    end

    # Polling helper to ensure eventual consistency before command is executed
    defp wait_for_projector(ou_id, person_id, expected_count, retries \\ 20) do
      if retries == 0 do
        flunk("Timeout waiting for read model to populate memberships")
      end

      memberships = AuroraGov.Context.MembershipContext.list_active_memberships_in_ou_subtree(ou_id, person_id)
      if length(memberships) >= expected_count do
        :ok
      else
        Process.sleep(100)
        wait_for_projector(ou_id, person_id, expected_count, retries - 1)
      end
    end

    test "fails to revoke if the OU does not exist" do
      command = %RevokeMembership{
        ou_id: "nonexistent_ou",
        person_id: "person_123"
      }

      assert {:error, :ou_not_exists} = dispatch_command(command)
    end

    test "fails to revoke if membership does not exist" do
      command = %RevokeMembership{
        ou_id: "root_ou",
        person_id: "person_123"
      }

      assert {:error, :membership_not_found} = dispatch_command(command)
    end
  end
end
