defmodule AuroraGov.Projector.ProposalProjector do
  alias AuroraGov.Projector.Model.Proposal
  alias AuroraGov.Event.ProposalCreated

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
end
