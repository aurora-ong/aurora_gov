defmodule AuroraGov.Web.Panel.EventRouter.ProjectorUpdate do
  require Logger
  import Phoenix.LiveView

  def handle_event({:membership_started, %{person: person, ou: ou} = _membership}, socket) do
    socket
    |> put_flash(
      :info,
      "#{person.person_name} (#{person.person_id}) ahora es miembro de #{ou.ou_name} (#{ou.ou_id})"
    )
  end

  def handle_event({:power_updated, power} = update, socket) do
    send_update(AuroraGov.Web.Live.Panel.Power,
      id: "panel-power",
      update: update
    )

    socket
    |> put_flash(
      :info,
      "#{power.power_id} se ha actualizado en (#{power.ou_id})"
    )
  end

  def handle_event({:vote_emited, vote} = update, socket) do
    send_update(AuroraGov.Web.Live.Panel.Side.ProposalDetail,
      id: "panel-proposal-#{vote.proposal_id}",
      update: update
    )

    socket
    |> put_flash(
      :info,
      "Se ha emitido un voto en (#{vote.proposal_id})"
    )
  end

  def handle_event({:proposal_executing, proposal} = update, socket) do
    send_update(AuroraGov.Web.Live.Panel.Side.ProposalDetail,
      id: "panel-proposal-#{proposal.proposal_id}",
      update: update
    )

    socket
    |> put_flash(
      :info,
      "Se está promulgando (#{proposal.proposal_title} #{proposal.proposal_id})"
    )
  end

  def handle_event({:proposal_consumed, proposal} = update, socket) do
    send_update(AuroraGov.Web.Live.Panel.Side.ProposalDetail,
      id: "panel-proposal-#{proposal.proposal_id}",
      update: update
    )

    socket
    |> put_flash(
      :info,
      "Se ha promulgando (#{proposal.proposal_title} #{proposal.proposal_id})"
    )
  end

  def handle_event({event, _data}, socket) do
    Logger.info("No se encontró ruta para #{event}")
    socket
  end

  def handle_event(data, socket) do
    Logger.warning("No se encontró ruta para #{inspect(data)}")
    socket
  end
end
