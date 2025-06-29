defmodule AuroraGov.Web.Utils do
  def person_has_vote_membership(membership) do
    # AuroraGov.Context.MembershipContext.get_membership(ou_id, person_id)
    # |> Enum.any?(fn membership ->
    #   membership.membership_status == "regular" || membership.membership_status == "senior"
    # end)
  end
end
