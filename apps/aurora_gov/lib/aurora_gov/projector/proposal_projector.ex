defmodule AuroraGov.Projector.ProposalProjector do
  alias AuroraGov.Projector.Model.Proposal

  alias AuroraGov.Event.{ProposalCreated, VoteEmited, ProposalExecuted, ProposalConsumed}
  import Ecto.Query

  def project(
        %ProposalCreated{} = event,
        _metadata,
        multi
      ) do
    proposal_votes =
      (event.proposal_voters || %{})
      |> Enum.map(fn {person_id, %{ou_id: ou_ids}} ->
        %AuroraGov.Projector.Model.Proposal.Vote{
          person_id: person_id,
          vote_ou: ou_ids,
          vote_value: nil,
          vote_type: nil,
          updated_at: nil
        }
      end)

    multi
    |> Ecto.Multi.insert(:proposal_insert, %Proposal{
      proposal_id: event.proposal_id,
      proposal_title: event.proposal_title,
      proposal_description: event.proposal_description,
      proposal_ou_start_id: event.proposal_ou_start_id,
      proposal_ou_end_id: event.proposal_ou_end_id,
      proposal_owner_id: event.proposal_owner_id,
      proposal_power_id: event.proposal_power_id,
      proposal_power_data: event.proposal_power_data,
      proposal_status: :active,
      proposal_votes: proposal_votes,
      proposal_power_sensibility: event.proposal_power_sensibility,
      created_at: DateTime.utc_now(),
      updated_at: DateTime.utc_now()
    })
    |> Ecto.Multi.run(:projector_update, fn _repo, %{proposal_insert: proposal} ->
      {:ok, {:proposal_created, proposal}}
    end)
  end

  def project(
        %VoteEmited{} = event,
        _metadata,
        multi
      ) do
    import Ecto.Query

    # Construye el JSON con los campos actualizados del voto
    updated_vote_fields = %{
      "vote_value" => event.vote_value,
      "vote_type" => event.vote_type,
      "updated_at" => DateTime.utc_now()
    }

    # Query para actualizar el voto dentro del array JSONB
    query =
      from(p in Proposal,
        where: p.proposal_id == ^event.proposal_id,
        update: [
          set: [
            proposal_votes:
              fragment(
                """
                (
                  SELECT jsonb_agg(
                    CASE
                      WHEN (elem->>'person_id')::text = ? THEN elem || ?::jsonb
                      ELSE elem
                    END
                  )
                  FROM jsonb_array_elements(proposal_votes) AS elem
                )
                """,
                ^event.person_id,
                ^updated_vote_fields
              ),
            updated_at: ^DateTime.utc_now()
          ]
        ]
      )

    multi
    |> Ecto.Multi.update_all(:vote_update, query, [])
    |> Ecto.Multi.run(:projector_update, fn _repo, %{vote_update: {1, _}} ->
      {:ok, {:vote_emited, event}}
    end)
  end

  def project(
        %ProposalExecuted{} = event,
        _metadata,
        multi
      ) do
    import Ecto.Query

    query =
      from(p in Proposal,
        where: p.proposal_id == ^event.proposal_id,
        update: [
          set: [
            proposal_status: :executing
          ]
        ],
        select: p
      )

    multi
    |> Ecto.Multi.update_all(:proposal_update, query, [])
    |> Ecto.Multi.run(:projector_update, fn _repo, %{proposal_update: {1, [updated_proposal]}} ->
      {:ok, {:proposal_executing, updated_proposal}}
    end)
  end

  def project(
        %ProposalConsumed{} = event,
        metadata,
        multi
      ) do
    query =
      from(p in Proposal,
        where: p.proposal_id == ^event.proposal_id,
        update: [
          set: [
            proposal_status: :consumed,
            proposal_execution_result: ^event.proposal_execution_result,
            proposal_execution_error: ^event.proposal_execution_error,
            consumed_at: ^metadata.created_at
          ]
        ],
        select: p
      )

    multi
    |> Ecto.Multi.update_all(:proposal_update, query, [])
    |> Ecto.Multi.run(:projector_update, fn _repo, %{proposal_update: {1, [updated_proposal]}} ->
      {:ok, {:proposal_consumed, updated_proposal}}
    end)
  end
end
