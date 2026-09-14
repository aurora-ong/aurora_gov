defmodule AuroraGov.Router do
  use Commanded.Commands.Router

  alias AuroraGov.Command.{
    RegisterPerson,
    CreateOU,
    RenameOU,
    UpdateOUGoal,
    StartMembership,
    UpdatePower,
    PromoteMembership,
    DowngradeMembership,
    RevokeMembership,
    CreateProposal,
    ApplyProposalVote,
    ConsumeProposal,
    ExecuteProposal,
    ActivatePowerDelegation,
    DeactivatePowerDelegation,
    CreateRole,
    AssignRole,
    UnassignRole,
    ArchiveRole,
    CreateProject,
    UpdateProject,
    ArchiveProject,
    TransferProject,
    CreateTask,
    UpdateTask,
    AssignTask,
    CompleteTask,
    AbandonTask,
    CancelTask,
    CreateResource,
    UpdateResource,
    CreateLedger,
    RecordTransaction,
    EvaluateTask
  }

  alias AuroraGov.CommandHandler.{
    RegisterPersonHandler,
    CreateOUHandler,
    RenameOUHandler,
    UpdateOUGoalHandler,
    StartMembershipHandler,
    UpdatePowerHandler,
    PromoteMembershipHandler,
    DowngradeMembershipHandler,
    RevokeMembershipHandler,
    CreateProposalHandler,
    ApplyProposalVoteHandler,
    ActivatePowerDelegationHandler,
    DeactivatePowerDelegationHandler,
    CreateRoleHandler,
    AssignRoleHandler,
    UnassignRoleHandler,
    ArchiveRoleHandler,
    ProjectHandler
  }

  alias AuroraGov.Aggregate.{Person, OU, Proposal, Ledger}

  # middleware AuthorizeCommand TODO AÑADIR PARA VERIFICAR PODERES

  dispatch(RegisterPerson, to: RegisterPersonHandler, aggregate: Person, identity: :person_id)
  dispatch(CreateOU, to: CreateOUHandler, aggregate: OU, identity: :ou_id)
  dispatch(RenameOU, to: RenameOUHandler, aggregate: OU, identity: :ou_id)
  dispatch(UpdateOUGoal, to: UpdateOUGoalHandler, aggregate: OU, identity: :ou_id)
  dispatch(StartMembership, to: StartMembershipHandler, aggregate: OU, identity: :ou_id)
  dispatch(PromoteMembership, to: PromoteMembershipHandler, aggregate: OU, identity: :ou_id)
  dispatch(DowngradeMembership, to: DowngradeMembershipHandler, aggregate: OU, identity: :ou_id)
  dispatch(RevokeMembership,to: RevokeMembershipHandler, aggregate: OU, identity: :ou_id)
  dispatch(UpdatePower, to: UpdatePowerHandler, aggregate: OU, identity: :ou_id)
  dispatch(ActivatePowerDelegation, to: ActivatePowerDelegationHandler, aggregate: OU,identity: :ou_id)
  dispatch(DeactivatePowerDelegation,to: DeactivatePowerDelegationHandler,aggregate: OU,identity: :ou_id)
  dispatch(CreateRole, to: CreateRoleHandler, aggregate: OU, identity: :ou_id)
  dispatch(AssignRole, to: AssignRoleHandler, aggregate: OU, identity: :ou_id)
  dispatch(UnassignRole, to: UnassignRoleHandler, aggregate: OU, identity: :ou_id)
  dispatch(ArchiveRole, to: ArchiveRoleHandler, aggregate: OU, identity: :ou_id)

  dispatch(
    [
      CreateProject,
      UpdateProject,
      ArchiveProject,
      TransferProject,
      CreateTask,
      UpdateTask,
      AssignTask,
      CompleteTask,
      AbandonTask,
      CancelTask,
      EvaluateTask
    ],
    to: ProjectHandler,
    aggregate: OU,
    identity: :ou_id
  )

  dispatch(CreateProposal, to: CreateProposalHandler, aggregate: Proposal, identity: :proposal_id)
  dispatch(ApplyProposalVote,to: ApplyProposalVoteHandler,aggregate: Proposal, identity: :proposal_id)

  dispatch([ExecuteProposal, ConsumeProposal],
    to: AuroraGov.Aggregate.Proposal,
    identity: :proposal_id,
    lifespan: AuroraGov.Aggregate.Proposal.Lifespan
  )

  def global_ledger_identity(_cmd), do: "global_ledger"

  dispatch(
    [
      CreateResource,
    UpdateResource,
    CreateLedger,
      RecordTransaction
    ],
    to: Ledger,
    identity: &__MODULE__.global_ledger_identity/1
  )
end
