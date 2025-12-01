defmodule AuroraGov.Aggregate.Proposal.Lifespan do
  @behaviour Commanded.Aggregates.AggregateLifespan

  def after_event(%AuroraGov.Event.ProposalConsumed{}), do: :stop
  def after_event(_event), do: :infinity

  def after_command(_command), do: :infinity
  def after_error(_error), do: :stop
end
