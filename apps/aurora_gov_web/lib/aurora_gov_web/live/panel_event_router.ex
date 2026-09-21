defmodule AuroraGov.Web.Panel.EventRouter.ProjectorUpdate do
  require Logger
  import Phoenix.LiveView
  import AuroraGov.Web.ToastHelper

  def handle_event({:ou_renamed, ou}, socket) do
    current_ou_id = socket.assigns.app_context.current_ou_id

    if current_ou_id == ou.ou_id do
      send_update(
        AuroraGov.Web.Live.Panel.Header,
        id: "header",
        app_context: socket.assigns.app_context
      )

      socket
      |> put_toast(
        "info",
        "La organización fue renombrada a #{ou.ou_name}."
      )
    else
      socket
    end
  end

  def handle_event({:ou_goal_updated, ou}, socket) do
    current_ou_id = socket.assigns.app_context.current_ou_id

    if current_ou_id == ou.ou_id do
      send_update(
        AuroraGov.Web.Live.Panel.Home,
        id: "panel-home",
        app_context: socket.assigns.app_context
      )

      socket
      |> put_toast(
        "info",
        "Se actualizó el objetivo de #{ou.ou_name}."
      )
    else
      socket
    end
  end

  def handle_event({:ou_avatar_updated, ou}, socket) do
    current_ou_id = socket.assigns.app_context.current_ou_id

    if current_ou_id == ou.ou_id do
      send_update(
        AuroraGov.Web.Live.Panel.Header,
        id: "header",
        app_context: socket.assigns.app_context
      )

      socket
      |> put_toast(
        "info",
        "Se actualizó el avatar de la unidad."
      )
    else
      socket
    end
  end

  def handle_event({:membership_started, %{person: person, ou: ou} = membership}, socket) do
    send_update(AuroraGov.Web.Live.Panel.Members,
      id: "panel-members",
      new_membership: membership
    )

    socket
    |> put_toast(
      "info",
      "#{person.person_name} (#{person.person_id}) ahora es miembro de #{ou.ou_name} (#{ou.ou_id})"
    )
  end

  def handle_event({:membership_promoted, %{person: person, ou: ou} = membership}, socket) do
    send_update(AuroraGov.Web.Live.Panel.Members,
      id: "panel-members",
      updated_membership: membership
    )

    socket
    |> put_toast(
      "info",
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
    |> put_toast(
      "info",
      "#{power.power_id} se ha actualizado en (#{power.ou_id})"
    )
  end

  def handle_event({:vote_emited, vote} = update, socket) do
    send_update(AuroraGov.Web.Live.Panel.Side.ProposalDetail,
      id: "panel-proposal-#{vote.proposal_id}",
      update: update
    )

    socket
    |> put_toast(
      "info",
      "Se ha emitido un voto en (#{vote.proposal_id})"
    )
  end

  def handle_event({:proposal_created, proposal} = update, socket) do
    send_update(AuroraGov.Web.Live.Panel.Proposals,
      id: "panel-proposal",
      proposal_event: update
    )

    socket
    |> put_toast(
      "info",
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
    |> put_toast(
      "info",
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
    |> put_toast(
      "info",
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

    socket |> put_toast("info", msg)
  end

  def handle_event({type, data} = event, socket)
      when type in [
             :project_created,
             :project_updated,
             :project_archived,
             :project_transferred,
             :task_created,
             :task_updated,
             :task_assigned,
             :task_completed,
             :task_abandoned,
             :task_cancelled
           ] do
    send_update(AuroraGov.Web.Live.Panel.Projects,
      id: "panel-projects",
      project_event: event
    )

    project_id = data.project_id
    send_update(AuroraGov.Web.Live.Panel.Side.ProjectDetail,
      id: "panel-project-#{project_id}",
      update: event
    )

    msg =
      case type do
        :project_created -> "Proyecto '#{data.name}' creado."
        :project_updated -> "Proyecto '#{data.name}' actualizado."
        :project_archived -> "Proyecto archivado."
        :project_transferred -> "Proyecto transferido."
        :task_created -> "Tarea '#{data.name}' creada."
        :task_updated -> "Tarea '#{data.name}' actualizada."
        :task_assigned -> "Tarea asignada al participante."
        :task_completed -> "Tarea marcada como completada."
        :task_abandoned -> "Tarea abandonada y devuelta al backlog."
        :task_cancelled -> "Tarea anulada."
      end

    socket |> put_toast("info", msg)
  end

  def handle_event({:resource_updated, resource}, socket) do
    send_update(AuroraGov.Web.Live.Panel.Resources,
      id: "panel-resources",
      resource_event: {:resource_updated, resource}
    )

    socket |> put_toast("info", "Recurso '#{resource.name}' actualizado.")
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
