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
        "Ahora se llama #{ou.ou_name}.",
        "Organización renombrada",
        "fa-sitemap"
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
        "#{ou.ou_name} tiene un nuevo objetivo.",
        "Objetivo actualizado",
        "fa-bullseye"
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
      "success",
      "#{person.person_name} se unió a #{ou.ou_name}.",
      "Nuevo miembro",
      "fa-users-between-lines"
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
      "#{person.person_name} ahora es #{membership.membership_rank} en #{ou.ou_name}.",
      "Cambio de rango",
      "fa-users-between-lines"
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
      "#{power.power_id}",
      "Poder actualizado",
      "fa-bolt"
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
      "Se emitió un voto en una propuesta.",
      "Nuevo voto",
      "fa-check-to-slot"
    )
  end

  def handle_event({:proposal_created, proposal} = update, socket) do
    send_update(AuroraGov.Web.Live.Panel.Proposals,
      id: "panel-proposal",
      proposal_event: update
    )

    socket
    |> put_toast(
      "success",
      "#{proposal.proposal_title}",
      "Nueva propuesta",
      "fa-hand"
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
      "#{proposal.proposal_title}",
      "Promulgando propuesta",
      "fa-hand"
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

    {kind, title, icon} =
      if Map.get(proposal, :proposal_execution_result) == "failed",
        do: {"error", "Error al promulgar", nil},
        else: {"success", "Propuesta promulgada", "fa-hand"}

    socket
    |> put_toast(
      kind,
      "#{proposal.proposal_title}",
      title,
      icon
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

    {kind, title, msg} =
      case type do
        :role_created -> {"success", "Rol creado", "#{data.role_name}"}
        :role_assigned -> {"info", "Rol asignado", "Se asignó a #{data.person_id}."}
        :role_unassigned -> {"info", "Rol quitado", "Se quitó a #{data.person_id}."}
        :role_archived -> {"info", nil, "Rol archivado."}
      end

    socket |> put_toast(kind, msg, title, "fa-id-card-clip")
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

    {kind, title, msg} =
      case type do
        :project_created -> {"success", "Proyecto creado", "#{data.name}"}
        :project_updated -> {"info", "Proyecto actualizado", "#{data.name}"}
        :project_archived -> {"info", nil, "Proyecto archivado."}
        :project_transferred -> {"info", nil, "Proyecto transferido."}
        :task_created -> {"success", "Tarea creada", "#{data.name}"}
        :task_updated -> {"info", "Tarea actualizada", "#{data.name}"}
        :task_assigned -> {"info", nil, "Tarea asignada al participante."}
        :task_completed -> {"success", nil, "Tarea marcada como completada."}
        :task_abandoned -> {"info", nil, "Tarea abandonada y devuelta al backlog."}
        :task_cancelled -> {"info", nil, "Tarea anulada."}
      end

    socket |> put_toast(kind, msg, title, "fa-briefcase")
  end

  def handle_event({:resource_updated, resource}, socket) do
    send_update(AuroraGov.Web.Live.Panel.Resources,
      id: "panel-resources",
      resource_event: {:resource_updated, resource}
    )

    socket |> put_toast("info", "#{resource.name}", "Recurso actualizado", "fa-piggy-bank")
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
