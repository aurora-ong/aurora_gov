defmodule AuroraGov.Projector.PowerProjector do
  alias AuroraGov.Projector.Model.OUPower
  alias AuroraGov.Projector.Model.Power
  alias AuroraGov.Event.PowerUpdated
  import Ecto.Query

  def project(
        %PowerUpdated{
          membership_id: membership_id,
          ou_id: ou_id,
          power_id: power_id,
          power_value: power_value,
          power_updated_at: power_updated_at
        },
        _metadata,
        multi
      ) do
    multi
    |> Ecto.Multi.run(:power_lookup, fn repo, _changes ->
      case repo.get_by(Power, membership_id: membership_id, ou_id: ou_id, power_id: power_id) do
        nil -> {:ok, nil}
        power -> {:ok, power}
      end
    end)
    |> Ecto.Multi.run(:power_upsert, fn repo, %{power_lookup: existing_power} ->
      changeset =
        case existing_power do
          nil ->
            Power.changeset(%Power{}, %{
              membership_id: membership_id,
              ou_id: ou_id,
              power_id: power_id,
              power_value: power_value,
              created_at: power_updated_at,
              updated_at: power_updated_at
            })

          %Power{} = power ->
            with {:ok, dt, _} <- DateTime.from_iso8601(power_updated_at) do
              Ecto.Changeset.change(power,
                power_value: power_value,
                updated_at: dt
              )
            end
        end

      repo.insert_or_update(changeset)
    end)
    |> Ecto.Multi.run(:ou_power_lookup, fn repo, _changes ->
      case repo.get_by(OUPower, ou_id: ou_id, power_id: power_id) do
        nil -> {:ok, nil}
        ou_power -> {:ok, ou_power}
      end
    end)
    |> Ecto.Multi.run(:ou_power_calc, fn repo, _changes ->
      power_list =
        Power
        |> where([p], p.ou_id == ^ou_id and p.power_id == ^power_id)
        |> repo.all()

      total = Enum.sum(Enum.map(power_list, & &1.power_value))
      count = length(power_list)
      average = if count > 0, do: Float.round(total / count, 2), else: 0

      {:ok,
       %{
         power_average: average,
         power_count: count
       }}
    end)
    |> Ecto.Multi.run(:ou_power_update, fn repo,
                                           %{
                                             ou_power_calc: ou_power_calc,
                                             ou_power_lookup: existing_ou_power
                                           } ->
      changeset =
        case existing_ou_power do
          nil ->
            OUPower.changeset(%OUPower{}, %{
              ou_id: ou_id,
              power_id: power_id,
              power_average: ou_power_calc.power_average,
              power_count: ou_power_calc.power_count
            })

          %OUPower{} = ou_power ->
            Ecto.Changeset.change(ou_power,
              power_average: ou_power_calc.power_average,
              power_count: ou_power_calc.power_count
            )
        end

      repo.insert_or_update(changeset)

      {:ok, :ok}
    end)
    |> Ecto.Multi.run(:projector_update, fn _repo,
                                            %{
                                              ou_power_calc: ou_power_calc
                                            } ->
      update = %{
        ou_id: ou_id,
        power_id: power_id,
        power_average: ou_power_calc.power_average,
        power_count: ou_power_calc.power_count
      }

      {:ok, {:power_updated, update}}
    end)
  end
end
