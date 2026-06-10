defmodule AuroraGov.Router do
  use Commanded.Commands.Router

  alias AuroraGov.Command.{
    RegisterPerson,
    CreateOU,
    StartMembership,
    UpdatePower,
    PromoteMembership,
    CreateProposal,
    ApplyProposalVote,
    ConsumeProposal,
    ExecuteProposal,
    ActivatePowerDelegation,
    DeactivatePowerDelegation
  }

  alias AuroraGov.CommandHandler.{
    RegisterPersonHandler,
    CreateOUHandler,
    StartMembershipHandler,
    UpdatePowerHandler,
    PromoteMembershipHandler,
    CreateProposalHandler,
    ApplyProposalVoteHandler,
    ActivatePowerDelegationHandler,
    DeactivatePowerDelegationHandler
  }

  alias AuroraGov.Aggregate.{Person, OU, Proposal}

  # middleware AuthorizeCommand TODO AÑADIR PARA VERIFICAR PODERES

  dispatch(RegisterPerson, to: RegisterPersonHandler, aggregate: Person, identity: :person_id)
  dispatch(CreateOU, to: CreateOUHandler, aggregate: OU, identity: :ou_id)
  dispatch(StartMembership, to: StartMembershipHandler, aggregate: OU, identity: :ou_id)
  dispatch(PromoteMembership, to: PromoteMembershipHandler, aggregate: OU, identity: :ou_id)
  dispatch(UpdatePower, to: UpdatePowerHandler, aggregate: OU, identity: :ou_id)
  dispatch(ActivatePowerDelegation, to: ActivatePowerDelegationHandler, aggregate: OU, identity: :ou_id)
  dispatch(DeactivatePowerDelegation, to: DeactivatePowerDelegationHandler, aggregate: OU, identity: :ou_id)
  dispatch(CreateProposal, to: CreateProposalHandler, aggregate: Proposal, identity: :proposal_id)

  dispatch(ApplyProposalVote,
    to: ApplyProposalVoteHandler,
    aggregate: Proposal,
    identity: :proposal_id
  )

  dispatch([ExecuteProposal, ConsumeProposal],
    to: AuroraGov.Aggregate.Proposal,
    identity: :proposal_id,
    lifespan: AuroraGov.Aggregate.Proposal.Lifespan
  )
end
