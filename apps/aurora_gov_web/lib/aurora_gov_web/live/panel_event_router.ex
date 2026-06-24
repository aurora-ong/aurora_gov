defmodule AuroraGov.Web.Panel.EventRouter.ProjectorUpdate do
  require Logger
  import Phoenix.LiveView

  def handle_event({:membership_started, %{person: person, ou: ou} = membership}, socket) do
    send_update(AuroraGov.Web.Live.Panel.Members,
      id: "panel-members",
      new_membership: membership
    )

    socket
    |> put_flash(
      :info,
      "#{person.person_name} (#{person.person_id}) ahora es miembro de #{ou.ou_name} (#{ou.ou_id})"
    )
  end

  def handle_event({:membership_promoted, %{person: person, ou: ou} = membership}, socket) do
    send_update(AuroraGov.Web.Live.Panel.Members,
      id: "panel-members",
      updated_membership: membership
    )

    socket
    |> put_flash(
      :info,
      "#{person.person_name} (#{person.person_id}) ahora tiene rango #{membership.membership_rank} en #{ou.ou_name} (#{ou.ou_id})"
    )
  end

  def handle_event({:power_updated, power} = update, socket) do
    send_update(AuroraGov.Web.Live.Panel.Power,
      id: "panel-power",
      update: update
    )

    send_update(AuroraGov.Web.Live.Panel.Side.PowerDetail,
      id: "power-detail-#{power.power_id}",
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

  def handle_event({:proposal_created, proposal} = update, socket) do
    send_update(AuroraGov.Web.Live.Panel.Proposals,
      id: "panel-proposal",
      proposal_event: update
    )

    socket
    |> put_flash(
      :info,
      "Propuesta creada (#{proposal.proposal_title})"
    )
  end

  def handle_event({:proposal_executing, proposal} = update, socket) do
    send_update(AuroraGov.Web.Live.Panel.Side.ProposalDetail,
      id: "panel-proposal-#{proposal.proposal_id}",
      update: update
    )

    send_update(AuroraGov.Web.Live.Panel.Proposals,
      id: "panel-proposal",
      proposal_event: update
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

    send_update(AuroraGov.Web.Live.Panel.Proposals,
      id: "panel-proposal",
      proposal_event: update
    )

    socket
    |> put_flash(
      :info,
      "Se ha promulgando (#{proposal.proposal_title} #{proposal.proposal_id})"
    )
  end

  def handle_event({:power_delegation_activated, delegation} = update, socket) do
    send_update(AuroraGov.Web.Live.Panel.Side.PowerDetail,
      id: "power-detail-#{delegation.power_id}",
      update: update
    )

    socket
  end

  def handle_event({:power_delegation_deactivated, delegation} = update, socket) do
    send_update(AuroraGov.Web.Live.Panel.Side.PowerDetail,
      id: "power-detail-#{delegation.power_id}",
      update: update
    )

    socket
  end

  def handle_event({type, data} = event, socket)
      when type in [:role_created, :role_assigned, :role_unassigned, :role_archived] do
    send_update(AuroraGov.Web.Live.Panel.Roles,
      id: "panel-roles",
      role_event: event
    )

    msg =
      case type do
        :role_created -> "Rol '#{data.role_name}' creado."
        :role_assigned -> "Rol asignado a #{data.person_id}."
        :role_unassigned -> "Rol quitado a #{data.person_id}."
        :role_archived -> "Rol archivado."
      end

    socket |> put_flash(:info, msg)
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
