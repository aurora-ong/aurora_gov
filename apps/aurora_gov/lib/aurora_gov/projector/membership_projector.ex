defmodule AuroraGov.Projector.MembershipProjector do
  alias AuroraGov.Projector.Model.Membership
  alias AuroraGov.Event.{MembershipStarted, MembershipPromoted}

  def project(
        %MembershipStarted{ou_id: ou_id, person_id: person_id},
        metadata,
        multi
      ) do
    params = %{
      ou_id: ou_id,
      person_id: person_id,
      membership_rank: :junior,
      membership_status: :active,
      created_at: metadata.created_at,
      updated_at: metadata.created_at
    }

    changeset = Membership.changeset(%Membership{}, params)

    multi
    |> Ecto.Multi.insert(:membership_table_insert, changeset, returning: true)
    |> Ecto.Multi.run(:projector_update, fn repo,
                                            %{membership_table_insert: membership_table_insert} ->
      membership =
        membership_table_insert
        |> repo.preload([:ou, :person])

      {:ok, {:membership_started, membership}}
    end)
  end

  def project(
        %MembershipPromoted{
          person_id: person_id,
          ou_id: ou_id,
          membership_rank: membership_rank
        },
        metadata,
        multi
      ) do
    multi
    |> Ecto.Multi.run(:membership_lookup, fn repo, _changes ->
      case repo.get_by(Membership, person_id: person_id, ou_id: ou_id) do
        nil -> {:error, :membership_not_found}
        membership -> {:ok, membership}
      end
    end)
    |> Ecto.Multi.update(:membership_update, fn %{membership_lookup: membership} ->
      Membership.changeset(membership, %{
        membership_rank: membership_rank,
        updated_at: metadata.created_at
      })
    end)
    |> Ecto.Multi.run(:projector_update, fn repo, %{membership_update: membership} ->
      membership
      |> repo.preload([:ou, :person])
      |> then(&{:ok, {:membership_promoted, &1}})
    end)
  end
end
