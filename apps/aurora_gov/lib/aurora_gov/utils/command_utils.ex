defmodule AuroraGov.CommandUtils do
  @proposable_power [
    Elixir.AuroraGov.Command.StartMembership,
    Elixir.AuroraGov.Command.CreateOU
  ]

  def all_proposable_modules do
    @proposable_power
    # |> Enum.map(&elem(&1, 0))
    # |> Enum.filter(&String.starts_with?(Atom.to_string(&1), "Elixir.AuroraGov.Command."))
    |> Enum.filter(&function_exported?(&1, :gov_power, 0))
  end

  def all_proposable_modules_select do
    @proposable_power
    # |> Enum.map(&elem(&1, 0))
    # |> Enum.filter(&String.starts_with?(Atom.to_string(&1), "Elixir.AuroraGov.Command."))
    # |> Enum.filter(&function_exported?(&1, :gov_power, 0))
    |> Enum.map(fn module ->
      power = module.gov_power()
      {power.name, power.id}
    end)
  end

  def find_command_by_id(id) do
    Enum.find(all_proposable_modules(), fn module ->
      module.gov_power().id == id
    end)
  end
end
