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
        app_side_panel: nil
      )

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    current_ou_id = get_current_ou_id(params)
    current_module = get_module_from_action(socket.assigns.live_action, params)

    socket =
      if current_ou_id != nil do
        socket
        |> assign(:app_modal, nil)
        |> assign(:app_context, %{
          socket.assigns.app_context
          | current_module: current_module,
            current_ou_id: current_ou_id
        })
        |> handle_deep_linking(socket.assigns.live_action, params)
      else
        socket
        |> push_patch(to: "/install")
      end

    {:noreply, socket}
  end

  # Helper para normalizar el nombre del módulo
  defp get_module_from_action(:members_show, _), do: "members"
  defp get_module_from_action(:members_index, _), do: "members"
  defp get_module_from_action(:proposals_show, _), do: "proposals"
  defp get_module_from_action(:proposals_index, _), do: "proposals"
  defp get_module_from_action(_, %{"module" => module}), do: module
  # Fallback
  defp get_module_from_action(_, _), do: "home"

  defp handle_deep_linking(socket, :proposals_show, %{"id" => id}) do
    app_panel = %AppView{
      view_id: "panel-proposal-#{id}",
      view_module: AuroraGov.Web.Live.Panel.Side.ProposalDetail,
      view_params: %{proposal_id: id}
    }

    assign(socket, :app_side_panel, app_panel)
  end

  # Si es una acción de lista (index), nos aseguramos de limpiar paneles viejos
  defp handle_deep_linking(socket, _action, _params) do
    assign(socket, :app_side_panel, nil)
  end

  defp get_current_ou_id(%{"context" => context}) when context != "", do: context

  defp get_current_ou_id(_params) do
    case (Enum.at(AuroraGov.Context.OUContext.list_ou(), 0) || %{}).ou_id do
      ou_id when is_binary(ou_id) and ou_id != "" ->
        ou_id

      _ ->
        nil
    end
  end

  @impl true
  def handle_info({:projector_update, event}, socket) do
    IO.inspect(event, label: "Actualizando PUBSUB Panel Live")
    socket = AuroraGov.Web.Panel.EventRouter.ProjectorUpdate.handle_event(event, socket)

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
      {:noreply, socket}
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
