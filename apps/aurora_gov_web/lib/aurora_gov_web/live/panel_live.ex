defmodule AuroraGov.Web.Live.Panel do
  use AuroraGov.Web, :live_view

  defmodule AppContext do
    defstruct [:current_ou_id, :current_person, :current_module]
  end

  defmodule AppView do
    @enforce_keys [:view_id, :view_module]
    @type t :: %__MODULE__{
            view_id: binary(),
            view_module: atom(),
            view_options: map(),
            view_params: map()
          }

    defstruct view_id: nil, view_module: nil, view_options: %{}, view_params: %{}
  end

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(AuroraGov.PubSub, "projector_update")
    end

    socket =
      assign(socket,
        app_context: %AppContext{current_person: socket.assigns.current_person},
        app_modal: nil,
        app_side_panel: nil,
        unread_activity: 0,
        app_global_search: %{
          query: "",
          results: %{},
          show_dropdown: false
        }
      )

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    current_ou_id = get_current_ou_id(params)
    current_module = get_module_from_action(socket.assigns.live_action, params)

    socket =
      if current_ou_id != nil do
        ou = AuroraGov.Context.OUContext.get_ou(current_ou_id)
        ou_name = if ou, do: ou.ou_name, else: "AuroraGov"
        page_title = "#{ou_name} · #{module_name_es(current_module)}"

        socket
        |> assign(:page_title, page_title)
        |> assign(:app_modal, nil)
        |> assign(:app_global_search, %{socket.assigns.app_global_search | show_dropdown: false})
        |> assign(:app_context, %{
          socket.assigns.app_context
          | current_module: current_module,
            current_ou_id: current_ou_id
        })
        |> handle_deep_linking(socket.assigns.live_action, params)
      else
        socket
        |> redirect(to: "/install")
      end

    {:noreply, socket}
  end

  # Helper para normalizar el nombre del módulo
  defp get_module_from_action(:members_show, _), do: "members"
  defp get_module_from_action(:members_index, _), do: "members"
  defp get_module_from_action(:proposals_show, _), do: "proposals"
  defp get_module_from_action(:proposals_index, _), do: "proposals"
  defp get_module_from_action(:projects_show, _), do: "projects"
  defp get_module_from_action(:projects_index, _), do: "projects"
  defp get_module_from_action(:tasks_show, _), do: "projects"
  defp get_module_from_action(:ledger_show, _), do: "resources"
  defp get_module_from_action(_, %{"module" => module}), do: module
  # Fallback
  defp get_module_from_action(_, _), do: "home"

  defp module_name_es("home"), do: "Inicio"
  defp module_name_es("culture"), do: "Cultura"
  defp module_name_es("members"), do: "Miembros"
  defp module_name_es("proposals"), do: "Propuestas"
  defp module_name_es("projects"), do: "Proyectos"
  defp module_name_es("resources"), do: "Recursos"
  defp module_name_es("settings"), do: "Configuración"
  defp module_name_es(name), do: String.capitalize(name)

  defp handle_deep_linking(socket, :members_show, %{"id" => id}) do
    app_panel = %AppView{
      view_id: "panel-member-#{id}",
      view_module: AuroraGov.Web.Live.Panel.Side.MemberDetail,
      view_params: %{person_id: id},
      view_options: %{panel_size: "w-4/12"}
    }

    assign(socket, :app_side_panel, app_panel)
  end

  defp handle_deep_linking(socket, :proposals_show, %{"id" => id}) do
    app_panel = %AppView{
      view_id: "panel-proposal-#{id}",
      view_module: AuroraGov.Web.Live.Panel.Side.ProposalDetail,
      view_params: %{proposal_id: id},
      view_options: %{panel_size: "w-5/12"}
    }

    assign(socket, :app_side_panel, app_panel)
  end

  defp handle_deep_linking(socket, :projects_show, %{"id" => id}) do
    app_panel = %AppView{
      view_id: "panel-project-#{id}",
      view_module: AuroraGov.Web.Live.Panel.Side.ProjectDetail,
      view_params: %{project_id: id},
      view_options: %{panel_size: "w-6/12"} # Give it slightly more space for products/tasks tree
    }

    assign(socket, :app_side_panel, app_panel)
  end

  defp handle_deep_linking(socket, :tasks_show, %{"id" => id}) do
    app_panel = %AppView{
      view_id: "panel-task-#{id}",
      view_module: AuroraGov.Web.Live.Panel.Side.TaskDetail,
      view_params: %{task_id: id},
      view_options: %{panel_size: "w-5/12"}
    }

    assign(socket, :app_side_panel, app_panel)
  end

  defp handle_deep_linking(socket, :ledger_show, %{"id" => id}) do
    app_panel = %AppView{
      view_id: "panel-ledger-#{id}",
      view_module: AuroraGov.Web.Live.Panel.Side.LedgerDetail,
      view_params: %{ledger_id: id},
      view_options: %{panel_size: "w-5/12"}
    }

    assign(socket, :app_side_panel, app_panel)
  end

  # Si es una acción de lista (index), nos aseguramos de limpiar paneles viejos
  defp handle_deep_linking(socket, _action, _params) do
    assign(socket, :app_side_panel, nil)
  end

  defp get_current_ou_id(%{"context" => context}) when context != "", do: context

  defp get_current_ou_id(_params) do
    case AuroraGov.Context.OUContext.list_ou() do
      [] -> nil
      [first_ou | _] -> first_ou.ou_id
    end
  end

  @impl true
  def handle_info({:projector_update, event}, socket) do
    IO.inspect(event, label: "Actualizando PUBSUB Panel Live")
    socket = AuroraGov.Web.Panel.EventRouter.ProjectorUpdate.handle_event(event, socket)
    socket = update(socket, :unread_activity, &(&1 + 1))

    {:noreply, socket}
  end

  @impl true
  def handle_info({:open, view_id, %AppView{} = app_view}, socket) do
    IO.inspect(app_view, label: "Abriendo #{view_id}")

    socket =
      socket
      |> assign(view_id, app_view)

    {:noreply, socket}
  end

  @impl true
  def handle_info({:close, view_id, id}, socket) do
    IO.inspect(id, label: "Cerrando #{view_id}")

    socket =
      socket
      |> assign(view_id, nil)

    {:noreply, socket}
  end

  @impl true
  def handle_info(event, socket) do
    IO.inspect(event, label: "handle_info desconocido")

    {:noreply, socket}
  end

  @impl true
  def handle_event("app_modal_close", %{"modal" => modal_id}, socket) do
    IO.inspect(modal_id, label: "Cerrando modal")
    {:noreply, assign(socket, app_modal: nil)}
  end

  @impl true
  def handle_event("global_search", %{"value" => query}, socket) do
    if byte_size(query) > 1 do
      results = AuroraGov.Context.GlobalSearch.search(query)
      {:noreply, assign(socket, app_global_search: %{query: query, results: results, show_dropdown: true})}
    else
      {:noreply, assign(socket, app_global_search: %{query: query, results: %{}, show_dropdown: false})}
    end
  end

  @impl true
  def handle_event("hide_global_search", _params, socket) do
    {:noreply, assign(socket, app_global_search: %{socket.assigns.app_global_search | show_dropdown: false})}
  end

  @impl true
  def handle_event("show_global_search", _params, socket) do
    if byte_size(socket.assigns.app_global_search.query) > 1 do
      {:noreply, assign(socket, app_global_search: %{socket.assigns.app_global_search | show_dropdown: true})}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("push_navigate", %{"url" => url}, socket) do
    {:noreply, push_navigate(socket, to: url)}
  end

  @impl true
  def handle_event("push_patch", %{"url" => url}, socket) do
    {:noreply, push_patch(socket, to: url)}
  end

  @impl true
  def handle_event("app_side_panel_close", %{"panel" => panel_id}, socket) do
    IO.inspect(panel_id, label: "Cerrando panel")
    {:noreply, assign(socket, app_side_panel: nil)}
  end

  @impl true
  def handle_event("toggle_activity_panel", _params, socket) do
    if (socket.assigns.app_side_panel && socket.assigns.app_side_panel.view_id) ==
         "panel-activity" do
      {:noreply, assign(socket, app_side_panel: nil)}
    else
      app_panel = %AppView{
        view_id: "panel-activity",
        view_module: AuroraGov.Web.Live.Panel.Side.LastActivity,
        view_options: %{},
        view_params: %{}
      }

      send(self(), {:open, :app_side_panel, app_panel})
      {:noreply, assign(socket, unread_activity: 0)}
    end
  end

  @impl true
  def handle_event(
        "open_proposal_create_modal",
        params,
        socket
      ) do
    {proposal_params, power_params} = split_proposal_params(params)

    app_view = %AppView{
      view_id: "modal-proposal_create",
      view_module: AuroraGov.Web.Live.Panel.ProposalCreate,
      view_options: %{
        modal_size: "quadruple_large"
      },
      view_params: %{
        proposal_params: proposal_params,
        power_params: power_params
      }
    }

    send(self(), {:open, :app_modal, app_view})

    {:noreply, socket}
  end

  defp split_proposal_params(params) do
    {power_raw, proposal_raw} =
      Map.split_with(params, fn {key, _val} -> String.starts_with?(key, "power-") end)

    power_data =
      Map.new(power_raw, fn {k, v} ->
        {String.replace_prefix(k, "power-", ""), v}
      end)

    proposal_data = Map.new(proposal_raw)

    {proposal_data, power_data}
  end

  defp get_close_path(_socket, app_context) do
    query_params = %{context: app_context.current_ou_id}

    ~p"/app/#{app_context.current_module}?#{query_params}"
  end
end
