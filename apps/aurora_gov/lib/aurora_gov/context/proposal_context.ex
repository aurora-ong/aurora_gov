defmodule AuroraGov.Context.ProposalContext do
  require Logger

  alias AuroraGov.Projector.Repo
  alias AuroraGov.Projector.Model.Proposal
  import Ecto.Query

  def create_proposal(proposal_attrs) do
    changeset = AuroraGov.Command.CreateProposal.handle_validate_create(proposal_attrs)

    case Ecto.Changeset.apply_action(changeset, :create) do
      {:ok, command} ->
        case AuroraGov.dispatch(command, consistency: :strong, returning: :execution_result) do
          {:ok, result} ->
            {:ok, result}

          {:error, reason} ->
            Logger.info(reason, name: "#{__MODULE__} create_proposal error")
        end

      {:error, invalid_changeset} ->
        {:error, invalid_changeset}
    end
  end

  def list_proposals(params \\ %{}) do
    q =
      Proposal
      |> order_by(desc: :created_at)

    {:ok, r} = Flop.validate_and_run(q, params)
    r
  end
end
