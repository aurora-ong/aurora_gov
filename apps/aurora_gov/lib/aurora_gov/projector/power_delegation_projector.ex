defmodule AuroraGov.Projector.PowerDelegationProjector do
  alias AuroraGov.Projector.Model.PowerDelegation
  alias AuroraGov.Event.PowerDelegationActivated
  alias AuroraGov.Event.PowerDelegationDeactivated

  def project(
        %PowerDelegationActivated{
          person_id: person_id,
          ou_id: ou_id,
          power_id: power_id
        },
        %{created_at: created_at},
        multi
      ) do
    multi
    |> Ecto.Multi.run(:power_delegation_lookup, fn repo, _changes ->
      case repo.get_by(PowerDelegation, person_id: person_id, ou_id: ou_id, power_id: power_id) do
        nil -> {:ok, nil}
        power -> {:ok, power}
      end
    end)
    |> Ecto.Multi.run(:power_delegation_upsert, fn repo,
                                                   %{
                                                     power_delegation_lookup:
                                                       existing_power_delegation
                                                   } ->
      changeset =
        case existing_power_delegation do
          nil ->
            PowerDelegation.changeset(%PowerDelegation{}, %{
              person_id: person_id,
              ou_id: ou_id,
              power_id: power_id,
              created_at: created_at,
              updated_at: created_at
            })

          %PowerDelegation{} = power_delegation ->
            Ecto.Changeset.change(power_delegation,
              updated_at: created_at
            )
        end

      repo.insert_or_update(changeset)
    end)
    |> Ecto.Multi.run(:projector_update, fn _repo, _changes ->
      {:ok,
       {:power_delegation_activated,
        %{
          person_id: person_id,
          ou_id: ou_id,
          power_id: power_id
        }}}
    end)
  end

  def project(
        %PowerDelegationDeactivated{
          person_id: person_id,
          ou_id: ou_id,
          power_id: power_id
        },
        _metadata,
        multi
      ) do
    multi
    |> Ecto.Multi.run(:power_delegation_lookup, fn repo, _changes ->
      case repo.get_by(PowerDelegation, person_id: person_id, ou_id: ou_id, power_id: power_id) do
        nil -> {:ok, nil}
        power -> {:ok, power}
      end
    end)
    |> Ecto.Multi.run(:power_delegation_delete, fn repo,
                                                   %{
                                                     power_delegation_lookup:
                                                       existing_power_delegation
                                                   } ->
      case existing_power_delegation do
        nil -> {:ok, nil}
        %PowerDelegation{} = power_delegation -> repo.delete(power_delegation)
      end
    end)
    |> Ecto.Multi.run(:projector_update, fn _repo, _changes ->
      {:ok,
       {:power_delegation_deactivated,
        %{
          person_id: person_id,
          ou_id: ou_id,
          power_id: power_id
        }}}
    end)
  end
end
