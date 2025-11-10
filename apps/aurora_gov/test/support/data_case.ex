# test/support/data_case.ex
defmodule AuroraGov.DataCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import Commanded.Assertions.EventAssertions
    end
  end

  setup do
    {:ok, _} = Application.ensure_all_started(:aurora_gov)

    on_exit(fn ->
      :ok = Application.stop(:aurora_gov)

      AuroraGov.Storage.reset!()
    end)

    :ok
  end
end
