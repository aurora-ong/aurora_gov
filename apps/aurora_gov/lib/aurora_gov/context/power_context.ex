defmodule AuroraGov.Context.PowerContext do
  @moduledoc """
  The Power context.
  """
  alias AuroraGov.Projector.Model.Power
  alias AuroraGov.Projector.Model.OUPower
  alias AuroraGov.Projector.Repo
  import Ecto.Query, warn: false

  ## Database getters

  def get_power(ou_id, person_id, power_id) do
    query =
      from(p in Power,
        where: p.ou_id == ^ou_id and p.person_id == ^person_id and p.power_id == ^power_id
      )
      |> preload([:person, :ou])

    Repo.one(query)
  end

  def get_ou_power_list(ou_id) do
    query = from(p in OUPower, where: p.ou_id == ^ou_id)
    Repo.all(query)
  end

  def get_ou_power(ou_id, power_id) do
    query =
      from(p in OUPower, where: p.ou_id == ^ou_id and p.power_id == ^power_id)

    Repo.one(query)
  end

  def update_person_power!(power_update_params) do
    changeset = AuroraGov.Command.UpdatePower.new(power_update_params)

    case Ecto.Changeset.apply_action(changeset, :register) do
      {:ok, command} ->
        case AuroraGov.dispatch(command, consistency: :strong, returning: :execution_result) do
          {:ok, result} ->
            {:ok, result}

          {:error, :person_already_exists} ->
            changeset =
              Ecto.Changeset.add_error(
                changeset,
                :person_id,
                "ya existe una cuenta con este id"
              )

            {:error, changeset}

          {:error, reason} ->
            {:error,
             Ecto.Changeset.add_error(
               changeset,
               :person_id,
               "Error inesperado: #{inspect(reason)}"
             )}
        end

      {:error, invalid_changeset} ->
        {:error, invalid_changeset}
    end
  end

  def get_power_metadata(power_id) do
    AuroraGov.CommandUtils.all_proposable_modules()
    |> Enum.map(fn module ->
      Map.merge(module.gov_power(), %{})
    end)
    |> Enum.find(fn info -> info.id == power_id end)
  end
end
