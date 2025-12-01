defmodule AuroraGov.Event.VoteEmited do
  @derive Jason.Encoder
  defstruct [
    :proposal_id,
    :person_id,
    :vote_id,
    :vote_value,
    :vote_comment,
    :vote_type
  ]
end
