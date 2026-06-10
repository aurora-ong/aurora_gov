defmodule AuroraGov.Context.GovPowerContext do
  @moduledoc """
  The GovPower context.
  """
  import Ecto.Query, warn: false

  @proposable_power [
    Elixir.AuroraGov.Command.StartMembership,
    Elixir.AuroraGov.Command.CreateOU,
    Elixir.AuroraGov.Command.PromoteMembership
  ]

  def list_gov_power do
    @proposable_power
    |> Enum.map(& &1.gov_power())
  end

  def get_gov_power(power_id) do
    case Enum.find(list_gov_power(), fn info ->
           info.id == power_id
         end) do
      nil -> {:error, :not_found}
      power -> {:ok, power}
    end
  end

  def get_gov_power!(power_id) do
    Enum.find(list_gov_power(), fn info ->
      info.id == power_id
    end) ||
      raise "Gov power not found: #{power_id}"
  end
end
