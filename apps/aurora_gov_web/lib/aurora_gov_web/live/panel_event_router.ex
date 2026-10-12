defmodule AuroraGov.Web.Panel.EventRouter.ProjectorUpdate do
  @moduledoc """
  Enruta los eventos del proyector recibidos vía PubSub (`"projector_update"`)
  hacia los LiveComponents correspondientes del Panel y despacha notificaciones Toast.
  """

  require Logger
  import Phoenix.LiveView
  import AuroraGov.Web.ToastHelper

  # ===========================================================================
  # 1. ORGANIZACIÓN (OU)
  # ===========================================================================

  def handle_event({type, ou}, socket)
      when type in [:ou_renamed, :ou_goal_updated, :ou_avatar_updated] do
    if socket.assigns.app_context.current_ou_id == ou.ou_id do
      case type do
        :ou_renamed ->
          send_update(AuroraGov.Web.Live.Panel.Header, id: "header", app_context: socket.assigns.app_context)
          put_toast(socket, "info", "Ahora se llama #{ou.ou_name}.", "Organización renombrada", "fa-sitemap")

        :ou_goal_updated ->
          send_update(AuroraGov.Web.Live.Panel.Home, id: "panel-home", app_context: socket.assigns.app_context)
          put_toast(socket, "info", "#{ou.ou_name} tiene un nuevo objetivo.", "Objetivo actualizado", "fa-bullseye")

        :ou_avatar_updated ->
          send_update(AuroraGov.Web.Live.Panel.Header, id: "header", app_context: socket.assigns.app_context)
          put_toast(socket, "info", "Se actualizó el avatar de #{ou.ou_name}.", "Avatar actualizado", "fa-sitemap")
      end
    else
      socket
    end
  end

  # ===========================================================================
  # 2. MEMBRESÍAS
  # ===========================================================================

  def handle_event({type, data}, socket)
      when type in [:membership_started, :membership_promoted, :membership_demoted, :membership_revoked] do
    case type do
      :membership_started ->
        send_update(AuroraGov.Web.Live.Panel.Members, id: "panel-members", new_membership: data)
        put_toast(socket, "success", "#{data.person.person_name} se unió a #{data.ou.ou_name}.", "Nuevo miembro", "fa-users-between-lines")

      :membership_promoted ->
        send_update(AuroraGov.Web.Live.Panel.Members, id: "panel-members", updated_membership: data)
        put_toast(socket, "info", "#{data.person.person_name} ahora es #{data.membership_rank} en #{data.ou.ou_name}.", "Cambio de rango", "fa-users-between-lines")

      :membership_demoted ->
        send_update(AuroraGov.Web.Live.Panel.Members, id: "panel-members", updated_membership: data)
        put_toast(socket, "info", "#{data.person.person_name} ahora es #{data.membership_rank} en #{data.ou.ou_name}.", "Cambio de rango", "fa-users-between-lines")

      :membership_revoked ->
        send_update(AuroraGov.Web.Live.Panel.Members, id: "panel-members", revoked_membership: %{person_id: data.person_id, ou_id: data.ou_id})
        put_toast(socket, "info", "La membresía de #{data.person_id} fue revocada en #{data.ou_id}.", "Membresía revocada", "fa-users-slash")
    end
  end

  # ===========================================================================
  # 3. ROLES
  # ===========================================================================

  def handle_event({type, data} = event, socket)
      when type in [:role_created, :role_assigned, :role_unassigned, :role_archived] do
    send_update(AuroraGov.Web.Live.Panel.Roles, id: "panel-roles", role_event: event)

    {kind, title, msg} =
      case type do
        :role_created -> {"success", "Rol creado", "#{data.role_name}"}
        :role_assigned -> {"info", "Rol asignado", "Se asignó a #{data.person_id}."}
        :role_unassigned -> {"info", "Rol quitado", "Se quitó a #{data.person_id}."}
        :role_archived -> {"info", nil, "Rol archivado."}
      end

    put_toast(socket, kind, msg, title, "fa-id-card-clip")
  end

  # ===========================================================================
  # 4. PODER Y DELEGACIONES
  # ===========================================================================

  def handle_event({type, data} = update, socket)
      when type in [:power_updated, :power_delegation_activated, :power_delegation_deactivated] do
    send_update(AuroraGov.Web.Live.Panel.Side.PowerDetail, id: "power-detail-#{data.power_id}", update: update)

    case type do
      :power_updated ->
        send_update(AuroraGov.Web.Live.Panel.Power, id: "panel-power", update: update)
        put_toast(socket, "info", "#{data.power_id}", "Poder actualizado", "fa-bolt")

      _delegation_event ->
        socket
    end
  end

  # ===========================================================================
  # 5. PROPUESTAS Y VOTACIÓN
  # ===========================================================================

  def handle_event({type, data} = update, socket)
      when type in [:proposal_created, :vote_emited, :proposal_executing, :proposal_consumed] do
    case type do
      :proposal_created ->
        send_update(AuroraGov.Web.Live.Panel.Proposals, id: "panel-proposal", proposal_event: update)
        put_toast(socket, "success", "#{data.proposal_title}", "Nueva propuesta", "fa-hand")

      :vote_emited ->
        send_update(AuroraGov.Web.Live.Panel.Side.ProposalDetail, id: "panel-proposal-#{data.proposal_id}", update: update)
        put_toast(socket, "info", "Se emitió un voto en una propuesta.", "Nuevo voto", "fa-check-to-slot")

      :proposal_executing ->
        send_update(AuroraGov.Web.Live.Panel.Side.ProposalDetail, id: "panel-proposal-#{data.proposal_id}", update: update)
        send_update(AuroraGov.Web.Live.Panel.Proposals, id: "panel-proposal", proposal_event: update)
        # put_toast(socket, "info", "#{data.proposal_title}", "Promulgando propuesta", "fa-hand")
        socket
      :proposal_consumed ->
        send_update(AuroraGov.Web.Live.Panel.Side.ProposalDetail, id: "panel-proposal-#{data.proposal_id}", update: update)
        send_update(AuroraGov.Web.Live.Panel.Proposals, id: "panel-proposal", proposal_event: update)

        {kind, title, icon} =
          if Map.get(data, :proposal_execution_result) == "failed",
            do: {"error", "Error al promulgar", nil},
            else: {"success", "Propuesta promulgada", "fa-hand"}

        put_toast(socket, kind, "#{data.proposal_title}", title, icon)
    end
  end

  # ===========================================================================
  # 6. PROYECTOS Y TAREAS
  # ===========================================================================

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
    send_update(AuroraGov.Web.Live.Panel.Projects, id: "panel-projects", project_event: event)
    send_update(AuroraGov.Web.Live.Panel.Side.ProjectDetail, id: "panel-project-#{data.project_id}", update: event)

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

    put_toast(socket, kind, msg, title, "fa-briefcase")
  end

  # ===========================================================================
  # 7. RECURSOS Y CONTABILIDAD (LEDGER)
  # ===========================================================================

  def handle_event({type, data} = event, socket)
      when type in [:resource_created, :resource_updated, :ledger_created, :transaction_recorded] do
    send_update(AuroraGov.Web.Live.Panel.Resources, id: "panel-resources", resource_event: event)

    {kind, title, msg, icon} =
      case type do
        :resource_created ->
          {"success", "Nuevo recurso", "#{data.name}", "fa-piggy-bank"}

        :resource_updated ->
          {"info", "Recurso actualizado", "#{data.name}", "fa-piggy-bank"}

        :ledger_created ->
          send_update(AuroraGov.Web.Live.Panel.Side.LedgerDetail, id: "panel-ledger-#{data.ledger_id}", update: event)
          {"success", "Cuenta contable creada", "#{data.name}", "fa-book"}

        :transaction_recorded ->
          if data.reference_id do
            send_update(AuroraGov.Web.Live.Panel.Side.LedgerDetail, id: "panel-ledger-#{data.reference_id}", update: event)
          end

          {"info", "Nueva transacción", "Transacción registrada en el libro mayor.", "fa-receipt"}
      end

    put_toast(socket, kind, msg, title, icon)
  end

  # ===========================================================================
  # 8. FALLBACKS
  # ===========================================================================

  def handle_event({event, _data}, socket) do
    Logger.info("No se encontró ruta para #{event}")
    socket
  end

  def handle_event(data, socket) do
    Logger.warning("No se encontró ruta para #{inspect(data)}")
    socket
  end
end
