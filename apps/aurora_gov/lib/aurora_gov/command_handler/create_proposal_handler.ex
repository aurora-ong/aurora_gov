defmodule AuroraGov.CommandHandler.CreateProposalHandler do
  @behaviour Commanded.Commands.Handler
  alias AuroraGov.Aggregate.{OU, Person, Proposal}
  alias AuroraGov.Command.CreateProposal
  alias AuroraGov.Event.ProposalCreated

  def handle(
        %Proposal{proposal_id: nil},
        %CreateProposal{
          proposal_id: proposal_id,
          proposal_ou_origin: ou_origin,
          proposal_ou_end: ou_end,
          proposal_person_id: person_id,
          proposal_title: title,
          proposal_description: description,
          proposal_power_id: power_id,
          proposal_power_data: power_data
        }
      ) do
    {:ou, ou_origin_agg} = OU.get_ou(ou_origin)
    IO.inspect(OU.get_membership(ou_origin_agg, person_id))
    # Validar OU de origen
    with {:ou, ou_origin_agg} <- OU.get_ou(ou_origin),
         :active <- ou_origin_agg.ou_status || :inactive,
         # Validar persona
         {:person, _person} <- Person.get_person(person_id),
         # Validar membresía de la persona en OU origen
         {:membership, membership} <- OU.get_membership(ou_origin_agg, person_id),
         true <- membership.membership_status in [:regular, :senior],
         # Validar OU de destino
         {:ou, ou_end_agg} <- OU.get_ou(ou_end),
         :active <- ou_end_agg.ou_status || :inactive do
      proposal_power = calculate_ou_tree_avg_power(ou_end, power_id)

      proposal_voters = calculate_proposal_voters(ou_end)
      # proposal_votes =
      IO.inspect(proposal_power, label: "Proposal Power")

      %ProposalCreated{
        proposal_id: proposal_id,
        proposal_title: title,
        proposal_description: description,
        proposal_ou_start_id: ou_origin,
        proposal_owner_id: person_id,
        proposal_power_id: power_id,
        proposal_power_data: power_data,
        proposal_power_sensibility: proposal_power,
        proposal_ou_end_id: ou_end,
        proposal_voters: proposal_voters
      }
    else
      {:error, :ou_not_exists} -> {:error, :ou_origin_not_exists}
      :inactive -> {:error, :ou_not_active}
      {:error, :person_not_exists} -> {:error, :person_not_exists}
      {:error, :membership_not_found} -> {:error, :person_not_member_of_ou}
      false -> {:error, :person_not_regular_or_senior}
      {:error, :ou_not_exists} -> {:error, :ou_end_not_exists}
    end
  end

  def handle(%Proposal{} = _aggregate, %CreateProposal{}) do
    {:error, :proposal_already_exists}
  end

  def calculate_proposal_voters(ou_id) do
    AuroraGov.Utils.OUTree.ou_tree_list(ou_id)
    |> Enum.reduce(%{}, fn sub_ou_id, acc ->
      case AuroraGov.Aggregate.OU.get_ou(sub_ou_id) do
        {:ou, ou} ->
          AuroraGov.Aggregate.OU.get_membership_with_vote_power(ou)
          |> Enum.reduce(acc, fn {person_id, _membership_status}, acc2 ->
            person_vote =
              Map.get(acc2, person_id, %{
                ou_id: []
              })

            updated_vote = %{
              person_vote
              | ou_id: Enum.uniq([sub_ou_id | person_vote.ou_id])
            }

            Map.put(acc2, person_id, updated_vote)
          end)

        _ ->
          acc
      end
    end)
  end

  defp calculate_ou_tree_avg_power(ou_id, power_id) do
    AuroraGov.Utils.OUTree.ou_tree_list(ou_id)
    |> Enum.reduce(%{}, fn sub_ou_id, acc ->
      {:ou, ou} = AuroraGov.Aggregate.OU.get_ou(sub_ou_id)
      {:ok, avg_power} = AuroraGov.Aggregate.OU.get_power_avg_sensitivity(ou, power_id)
      Map.put(acc, sub_ou_id, avg_power)
    end)
  end
end
