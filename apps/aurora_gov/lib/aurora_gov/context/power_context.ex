defmodule AuroraGov.Context.PowerContext do
  @moduledoc """
  The Power context.
  """
  alias AuroraGov.Projector.Model.Power
  alias AuroraGov.Projector.Repo
  import Ecto.Query, warn: false

  def get_power(ou_id, person_id, power_id) do
    query =
      from(p in Power,
        where: p.ou_id == ^ou_id and p.person_id == ^person_id and p.power_id == ^power_id
      )
      |> preload([:person, :ou])

    Repo.one(query)
  end

  def list_power_sensitivities(ou_id, power_id) do
    query =
      from(p in Power,
        where: p.ou_id == ^ou_id and p.power_id == ^power_id,
        order_by: [desc: p.updated_at]
      )
      |> preload([:person])

    Repo.all(query)
  end

  def update_power!(power_update_params) do
    changeset = AuroraGov.Command.UpdatePower.new(power_update_params)

    case Ecto.Changeset.apply_action(changeset, :register) do
      {:ok, command} ->
        case AuroraGov.dispatch(command, consistency: :strong, returning: :execution_result) do
          {:ok, result} ->
            {:ok, result}

          {:error, reason} ->
            {:error, reason}
        end

      {:error, invalid_changeset} ->
        {:error, invalid_changeset}
    end
  end
end
