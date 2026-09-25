defmodule AuroraGov.Integrations.Discord.ProposalData do
  @moduledoc """
  Recupera los datos necesarios para presentar una propuesta en Discord.
  """

  alias AuroraGov.Context.{GovPowerContext, ProposalContext}
  alias AuroraGov.Projector.Model.Proposal

  @doc """
  Devuelve la propuesta y las opciones de presentación.

  Si la proyección todavía no existe, el handler podrá reintentar.
  """
  def fetch(proposal_id, metadata) do
    case ProposalContext.get_proposal_by_id(proposal_id) do
      %Proposal{} = proposal ->
        opts = [
          owner_name: name(proposal.proposal_owner, :person_name),
          origin_name: name(proposal.proposal_ou_start, :ou_name),
          destination_name: name(proposal.proposal_ou_end, :ou_name),
          power_name: power_name(proposal.proposal_power_id),
          occurred_at: Map.get(metadata, :created_at)
        ]

        {:ok, proposal, opts}

      nil ->
        {:error, :proposal_not_projected}
    end
  end

  defp power_name(power_id) do
    case GovPowerContext.get_gov_power(power_id) do
      {:ok, power} -> power.name
      {:error, :not_found} -> nil
    end
  end

  defp name(record, field) when is_map(record) do
    Map.get(record, field)
  end

  defp name(_record, _field), do: nil
end
