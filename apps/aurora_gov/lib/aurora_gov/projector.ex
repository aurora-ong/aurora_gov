defmodule AuroraGov.Projector do
  use Commanded.Projections.Ecto,
    application: AuroraGov,
    repo: AuroraGov.Projector.Repo,
    name: "aurora_gov-projector-main",
    consistency: :strong

  require Logger

  alias AuroraGov.Projector.{
    PersonProjector,
    MembershipProjector,
    PowerProjector,
    PowerDelegationProjector,
    ProposalProjector,
    OURoleProjector,
    OUProjector,
    ProjectProjector,
    LedgerProjector
  }

  alias AuroraGov.Event.{
    PersonRegistered,
    OUCreated,
    OURenamed,
    OUGoalUpdated,
    OUAvatarUpdated,
    MembershipStarted,
    ProposalCreated,
    ProposalExecuted,
    ProposalConsumed,
    VoteEmited,
    MembershipPromoted,
    MembershipDemoted,
    MembershipRevoked,
    PowerUpdated,
    PowerDelegationActivated,
    PowerDelegationDeactivated,
    OURoleCreated,
    OURoleAssigned,
    OURoleUnassigned,
    OURoleArchived,
    ProjectCreated,
    ProjectUpdated,
    ProjectArchived,
    ProjectTransferred,
    TaskCreated,
    TaskUpdated,
    TaskAssigned,
    TaskCompleted,
    TaskAbandoned,
    TaskCancelled,
    TaskEvaluated,
    ResourceCreated,
    ResourceUpdated,
    LedgerCreated,
    TransactionRecorded
  }

  project(%PersonRegistered{} = evt, metadata, &PersonProjector.project(evt, metadata, &1))

  project(%OUCreated{} = evt, metadata, &OUProjector.project(evt, metadata, &1))

  project(%OURenamed{} = evt, metadata, &OUProjector.project(evt, metadata, &1))

  project(%OUGoalUpdated{} = evt, metadata, &OUProjector.project(evt, metadata, &1))

  project(%OUAvatarUpdated{} = evt, metadata, &OUProjector.project(evt, metadata, &1))

  project(%MembershipStarted{} = evt, metadata, &MembershipProjector.project(evt, metadata, &1))

  project(%ProposalCreated{} = evt, metadata, &ProposalProjector.project(evt, metadata, &1))

  project(%ProposalExecuted{} = evt, metadata, &ProposalProjector.project(evt, metadata, &1))

  project(%ProposalConsumed{} = evt, metadata, &ProposalProjector.project(evt, metadata, &1))

  project(%VoteEmited{} = evt, metadata, &ProposalProjector.project(evt, metadata, &1))

  project(%MembershipPromoted{} = evt, metadata, &MembershipProjector.project(evt, metadata, &1))

  project(%MembershipDemoted{} = evt, metadata, &MembershipProjector.project(evt, metadata, &1))

  project(%MembershipRevoked{} = evt, metadata, &MembershipProjector.project(evt, metadata, &1))

  project(%PowerUpdated{} = evt, metadata, &PowerProjector.project(evt, metadata, &1))

  project(
    %PowerDelegationActivated{} = evt,
    metadata,
    &PowerDelegationProjector.project(evt, metadata, &1)
  )

  project(
    %PowerDelegationDeactivated{} = evt,
    metadata,
    &PowerDelegationProjector.project(evt, metadata, &1)
  )

  project(%OURoleCreated{} = evt, metadata, &OURoleProjector.project(evt, metadata, &1))

  project(%OURoleAssigned{} = evt, metadata, &OURoleProjector.project(evt, metadata, &1))

  project(%OURoleUnassigned{} = evt, metadata, &OURoleProjector.project(evt, metadata, &1))

  project(%OURoleArchived{} = evt, metadata, &OURoleProjector.project(evt, metadata, &1))

  project(%ProjectCreated{} = evt, metadata, &ProjectProjector.project(evt, metadata, &1))
  project(%ProjectUpdated{} = evt, metadata, &ProjectProjector.project(evt, metadata, &1))
  project(%ProjectArchived{} = evt, metadata, &ProjectProjector.project(evt, metadata, &1))
  project(%ProjectTransferred{} = evt, metadata, &ProjectProjector.project(evt, metadata, &1))
  project(%TaskCreated{} = evt, metadata, &ProjectProjector.project(evt, metadata, &1))
  project(%TaskUpdated{} = evt, metadata, &ProjectProjector.project(evt, metadata, &1))
  project(%TaskAssigned{} = evt, metadata, &ProjectProjector.project(evt, metadata, &1))
  project(%TaskCompleted{} = evt, metadata, &ProjectProjector.project(evt, metadata, &1))
  project(%TaskAbandoned{} = evt, metadata, &ProjectProjector.project(evt, metadata, &1))
  project(%TaskCancelled{} = evt, metadata, &ProjectProjector.project(evt, metadata, &1))
  project(%TaskEvaluated{} = evt, metadata, &ProjectProjector.project(evt, metadata, &1))

  # Ledger
  project(%ResourceCreated{} = evt, metadata, &LedgerProjector.project(evt, metadata, &1))
  project(%ResourceUpdated{} = evt, metadata, &LedgerProjector.project(evt, metadata, &1))
  project(%LedgerCreated{} = evt, metadata, &LedgerProjector.project(evt, metadata, &1))
  project(%TransactionRecorded{} = evt, metadata, &LedgerProjector.project(evt, metadata, &1))

  @impl Commanded.Projections.Ecto
  def after_update(event, _metadata, %{projector_update: projector_update}) do
    Logger.debug(
      "PROYECTOR: Notificando (projector_update) #{inspect(projector_update)} para evento #{inspect(event.__struct__)}"
    )

    Phoenix.PubSub.broadcast(
      AuroraGov.PubSub,
      "projector_update",
      {:projector_update, projector_update}
    )

    :ok
  end

  @impl Commanded.Projections.Ecto
  def after_update(event, _metadata, data) do
    Logger.debug(
      "PROYECTOR: after_update sin projector_update para evento #{inspect(event.__struct__)}. Data: #{inspect(data)}"
    )

    :ok
  end

  @impl true
  def error({:error, error}, event, _failure_context) do
    Logger.error("Error al proyectar #{inspect(error)} #{inspect(event)}")
    :skip
  end
end
