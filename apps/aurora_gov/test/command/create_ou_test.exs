defmodule AuroraGov.Command.CreateOUTest do
  use AuroraGov.DataCase, async: false

  alias AuroraGov.Command.CreateOU
  alias AuroraGov.Event.OUCreated

  test "should create an ou when data is valid" do
    ou_id = "test_ou"
    ou_name = Faker.StarWars.character()
    ou_goal = Faker.StarWars.quote()
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
    parent_ou_goal = Faker.StarWars.quote()
    parent_ou_description = Faker.StarWars.quote()

    # Despachar el comando para crear el padre
    child_ou_id = parent_ou_id <> ".child_ou"
    child_ou_name = Faker.StarWars.character()
    child_ou_goal = Faker.StarWars.quote()
    child_ou_description = Faker.StarWars.quote()

    :ok =
      AuroraGov.dispatch(%CreateOU{
        ou_id: parent_ou_id,
        ou_name: parent_ou_name,
        ou_goal: parent_ou_goal,
        ou_description: parent_ou_description
      })

    # Aserción para el evento del padre. Usar 'assert' dentro de la función anónima
    # consume el evento del buzón.
    assert_receive_event(AuroraGov, OUCreated, fn event ->
      assert event.ou_id == parent_ou_id
      assert event.ou_name == parent_ou_name
      assert event.ou_goal == parent_ou_goal
      assert event.ou_description == parent_ou_description
    end)

    # Despachar el comando para crear el hijo
    :ok =
      AuroraGov.dispatch(%CreateOU{
        ou_id: child_ou_id,
        ou_name: child_ou_name,
        ou_goal: child_ou_goal,
        ou_description: child_ou_description
      })

    # Aserción para el evento del hijo.
    assert_receive_event(AuroraGov, OUCreated, fn event ->
      assert event.ou_id == child_ou_id
      assert event.ou_name == child_ou_name
      assert event.ou_goal == child_ou_goal
      assert event.ou_description == child_ou_description
    end)
  end

  test "should create a grandchild ou when parent and grandparent exists" do
    parent_ou_id = "parent_ou"
    parent_ou_name = Faker.StarWars.character()
    parent_ou_goal = Faker.StarWars.quote()
    parent_ou_description = Faker.StarWars.quote()

    child_ou_id = parent_ou_id <> ".child_ou"
    child_ou_name = Faker.StarWars.character()
    child_ou_goal = Faker.StarWars.quote()
    child_ou_description = Faker.StarWars.quote()

    grandchild_ou_id = child_ou_id <> ".grandchild_ou"
    grandchild_ou_name = Faker.StarWars.character()
    grandchild_ou_goal = Faker.StarWars.quote()
    grandchild_ou_description = Faker.StarWars.quote()

    # Despachar el comando para crear el abuelo
    :ok =
      AuroraGov.dispatch(%CreateOU{
        ou_id: parent_ou_id,
        ou_name: parent_ou_name,
        ou_goal: parent_ou_goal,
        ou_description: parent_ou_description
      })

    # Aserción para el evento del abuelo
    assert_receive_event(AuroraGov, OUCreated, fn event ->
      assert event.ou_id == parent_ou_id
      assert event.ou_name == parent_ou_name
      assert event.ou_goal == parent_ou_goal
      assert event.ou_description == parent_ou_description
    end)

    # Despachar el comando para crear el padre
    :ok =
      AuroraGov.dispatch(%CreateOU{
        ou_id: child_ou_id,
        ou_name: child_ou_name,
        ou_goal: child_ou_goal,
        ou_description: child_ou_description
      })

    # Aserción para el evento del padre
    assert_receive_event(AuroraGov, OUCreated, fn event ->
      assert event.ou_id == child_ou_id
      assert event.ou_name == child_ou_name
      assert event.ou_goal == child_ou_goal
      assert event.ou_description == child_ou_description
    end)

    # Despachar el comando para crear el hijo
    :ok =
      AuroraGov.dispatch(%CreateOU{
        ou_id: grandchild_ou_id,
        ou_name: grandchild_ou_name,
        ou_goal: grandchild_ou_goal,
        ou_description: grandchild_ou_description
      })

    # Aserción para el evento del hijo
    assert_receive_event(AuroraGov, OUCreated, fn event ->
      assert event.ou_id == grandchild_ou_id
      assert event.ou_name == grandchild_ou_name
      assert event.ou_goal == grandchild_ou_goal
      assert event.ou_description == grandchild_ou_description
    end)
  end

  test "should return error when parent does not exist" do
    parent_ou_id = "non_existent_parent"
    child_ou_id = parent_ou_id <> ".child_ou"
    child_ou_name = Faker.StarWars.character()
    child_ou_goal = Faker.StarWars.quote()
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
