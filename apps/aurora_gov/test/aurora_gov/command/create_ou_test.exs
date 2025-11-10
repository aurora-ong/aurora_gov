defmodule AuroraGov.Command.CreateOUTest do
  use ExUnit.Case, async: true
  use Commanded.Aggregates.TestCase,
    application: AuroraGov.Application,
    aggregate: AuroraGov.Aggregate.OU,
    router: AuroraGov.Router

  alias AuroraGov.Command.CreateOU
  alias AuroraGov.Event.OUCreated

  setup do
    ou_id = "test_ou"
    ou_name = Faker.StarWars.character()
    ou_description = Faker.StarWars.quote()
    ou_goal = Faker.StarWars.specie()

    %{
      ou_id: ou_id,
      ou_name: ou_name,
      ou_goal: ou_goal,
      ou_description: ou_description
    }
  end

  test "should create an ou when data is valid", %{
    ou_id: ou_id,
    ou_name: ou_name,
    ou_goal: ou_goal,
    ou_description: ou_description
  } do
    assert_dispatch(
      %CreateOU{
        ou_id: ou_id,
        ou_name: ou_name,
        ou_goal: ou_goal,
        ou_description: ou_description
      },
      {:ok,
       %OUCreated{
         ou_id: ou_id
       }}
    )
  end

  test "should create a child ou when parent exists", %{
    ou_name: ou_name,
    ou_goal: ou_goal,
    ou_description: ou_description
  } do
    parent_ou_id = "parent_ou"

    dispatch(%CreateOU{
      ou_id: parent_ou_id,
      ou_name: ou_name,
      ou_goal: ou_goal,
      ou_description: ou_description
    })

    child_ou_id = parent_ou_id <> ".child_ou"

    assert_dispatch(
      %CreateOU{
        ou_id: child_ou_id,
        ou_name: "Child OU",
        ou_goal: "Child Goal",
        ou_description: "Child Description"
      },
      {:ok, %OUCreated{ou_id: child_ou_id}}
    )
  end

  test "should create a grandchild ou when parent and grandparent exists", %{
    ou_name: ou_name,
    ou_goal: ou_goal,
    ou_description: ou_description
  } do
    parent_ou_id = "parent_ou"

    dispatch(%CreateOU{
      ou_id: parent_ou_id,
      ou_name: ou_name,
      ou_goal: ou_goal,
      ou_description: ou_description
    })

    child_ou_id = parent_ou_id <> ".child_ou"

    dispatch(%CreateOU{
      ou_id: child_ou_id,
      ou_name: "Child OU",
      ou_goal: "Child Goal",
      ou_description: "Child Description"
    })

    grandchild_ou_id = child_ou_id <> ".grandchild_ou"

    assert_dispatch(
      %CreateOU{
        ou_id: grandchild_ou_id,
        ou_name: "Grandchild OU",
        ou_goal: "Grandchild Goal",
        ou_description: "Grandchild Description"
      },
      {:ok, %OUCreated{ou_id: grandchild_ou_id}}
    )
  end

  test "should return error when parent does not exist" do
    parent_ou_id = "non_existent_parent"
    child_ou_id = parent_ou_id <> ".child_ou"

    assert_dispatch(
      %CreateOU{
        ou_id: child_ou_id,
        ou_name: "Child OU",
        ou_goal: "Child Goal",
        ou_description: "Child Description"
      },
      {:error, :uo_parent_not_exists}
    )
  end

end
