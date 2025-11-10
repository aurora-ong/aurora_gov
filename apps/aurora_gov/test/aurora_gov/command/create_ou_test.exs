defmodule AuroraGov.Command.CreateOUTest do
  use AuroraGov.DataCase

  alias AuroraGov.Command.CreateOU
  alias AuroraGov.Event.OUCreated

  test "should create an ou when data is valid" do
    ou_id = "test_ou"
    ou_name = Faker.StarWars.character()
    ou_goal = Faker.StarWars.specie()
    ou_description = Faker.StarWars.quote()

    :ok =
      AuroraGov.dispatch(%CreateOU{
        ou_id: ou_id,
        ou_name: ou_name,
        ou_goal: ou_goal,
        ou_description: ou_description
      })

    assert_receive_event(AuroraGov, OUCreated, fn event ->
      assert event.ou_id == ou_id
    end)
  end

  test "should create a child ou when parent exists" do
    parent_ou_id = "parent_ou"
    parent_ou_name = Faker.StarWars.character()
    parent_ou_goal = Faker.StarWars.specie()
    parent_ou_description = Faker.StarWars.quote()

    :ok =
      AuroraGov.dispatch(%CreateOU{
        ou_id: parent_ou_id,
        ou_name: parent_ou_name,
        ou_goal: parent_ou_goal,
        ou_description: parent_ou_description
      })

    assert_receive_event(AuroraGov, OUCreated, fn event -> event.ou_id == parent_ou_id end)

    child_ou_id = parent_ou_id <> ".child_ou"
    child_ou_name = Faker.StarWars.character()
    child_ou_goal = Faker.StarWars.specie()
    child_ou_description = Faker.StarWars.quote()

    :ok =
      AuroraGov.dispatch(%CreateOU{
        ou_id: child_ou_id,
        ou_name: child_ou_name,
        ou_goal: child_ou_goal,
        ou_description: child_ou_description
      })

    assert_receive_event(AuroraGov, OUCreated, fn event ->
      assert event.ou_id == child_ou_id
    end)
  end

  test "should create a grandchild ou when parent and grandparent exists" do
    parent_ou_id = "parent_ou"
    parent_ou_name = Faker.StarWars.character()
    parent_ou_goal = Faker.StarWars.specie()
    parent_ou_description = Faker.StarWars.quote()

    :ok =
      AuroraGov.dispatch(%CreateOU{
        ou_id: parent_ou_id,
        ou_name: parent_ou_name,
        ou_goal: parent_ou_goal,
        ou_description: parent_ou_description
      })

    assert_receive_event(AuroraGov, OUCreated, fn event -> event.ou_id == parent_ou_id end)

    child_ou_id = parent_ou_id <> ".child_ou"
    child_ou_name = Faker.StarWars.character()
    child_ou_goal = Faker.StarWars.specie()
    child_ou_description = Faker.StarWars.quote()

    :ok =
      AuroraGov.dispatch(%CreateOU{
        ou_id: child_ou_id,
        ou_name: child_ou_name,
        ou_goal: child_ou_goal,
        ou_description: child_ou_description
      })

    assert_receive_event(AuroraGov, OUCreated, fn event -> event.ou_id == child_ou_id end)

    grandchild_ou_id = child_ou_id <> ".grandchild_ou"
    grandchild_ou_name = Faker.StarWars.character()
    grandchild_ou_goal = Faker.StarWars.specie()
    grandchild_ou_description = Faker.StarWars.quote()

    :ok =
      AuroraGov.dispatch(%CreateOU{
        ou_id: grandchild_ou_id,
        ou_name: grandchild_ou_name,
        ou_goal: grandchild_ou_goal,
        ou_description: grandchild_ou_description
      })

    assert_receive_event(AuroraGov, OUCreated, fn event ->
      assert event.ou_id == grandchild_ou_id
    end)
  end

  test "should return error when parent does not exist" do
    parent_ou_id = "non_existent_parent"
    child_ou_id = parent_ou_id <> ".child_ou"
    child_ou_name = Faker.StarWars.character()
    child_ou_goal = Faker.StarWars.specie()
    child_ou_description = Faker.StarWars.quote()

    assert {:error, :uo_parent_not_exists} ==
             AuroraGov.dispatch(%CreateOU{
               ou_id: child_ou_id,
               ou_name: child_ou_name,
               ou_goal: child_ou_goal,
               ou_description: child_ou_description
             })
  end
end
