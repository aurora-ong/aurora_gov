defmodule AuroraGov.Projector.MembershipProjector do
  alias AuroraGov.Projector.Model.Membership
  alias AuroraGov.Event.MembershipStarted

  def project(
        %MembershipStarted{membership_id: membership_id, ou_id: ou_id, person_id: person_id},
        metadata,
        multi
      ) do
    projection = %Membership{
      membership_id: membership_id,
      ou_id: ou_id,
      person_id: person_id,
      membership_status: "junior",
      created_at: metadata.created_at,
      updated_at: metadata.created_at
    }

    multi
    |> Ecto.Multi.insert(:membership_table_insert, projection, returning: true)
    |> Ecto.Multi.run(:projector_update, fn repo,
                                            %{membership_table_insert: membership_table_insert} ->
      membership =
        membership_table_insert
        |> repo.preload([:ou, :person])

      {:ok, {:membership_started, membership}}
    end)
  end
end
