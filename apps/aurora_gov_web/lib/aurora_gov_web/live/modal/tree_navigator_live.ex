defmodule AuroraGovWeb.Live.Panel.TreeNavigator do
  alias Phoenix.LiveView.AsyncResult
  use AuroraGovWeb, :live_component
  import AuroraGovWeb.OUVisualTreeComponent
  import AuroraGov.Utils.OUTree

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:ou_tree, AsyncResult.loading())

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(:context, assigns.context)
      |> assign(:module, assigns.app_module)
      |> start_async(:load_data, fn ->
        if assigns[:current_person] != nil do
          AuroraGov.Context.OUContext.get_ou_tree_with_membership(
            assigns[:current_person].person_id
          )
        else
          AuroraGov.Context.OUContext.get_ou_tree()
          |> Enum.map(&Map.from_struct/1)
        end
      end)

    {:ok, socket}
  end

  @impl true
  def handle_async(:load_data, {:ok, ou_tree}, socket) do
    %{ou_tree: ou_tree_async} = socket.assigns
    {:noreply, assign(socket, :ou_tree, AsyncResult.ok(ou_tree_async, ou_tree))}
  end

  # ============ UI SUBCOMPONENTS (HEEx) ============

  # Chip / badge neutro (usa {} en lugar de <%= %>)
  attr :icon_class, :string, default: nil
  slot :inner_block, required: true

  defp chip(assigns) do
    ~H"""
    <span class="inline-flex items-center gap-1 rounded-md border border-gray-300 bg-gray-50 px-2 py-0.5 text-xs font-medium text-gray-700">
      <i :if={@icon_class} class={@icon_class}></i> {render_slot(@inner_block)}
    </span>
    """
  end

  # Badge de membresía (sin with_attrs; cálculo en Elixir + assigns)
  attr :status, :any, required: true

  defp membership_badge(assigns) do
    assigns =
      if is_nil(assigns.status) do
        assigns
      else
        {label, icon} = membership_style(assigns.status)

        assigns
        |> assign(:m_label, label)
        |> assign(:m_icon, icon)
      end

    ~H"""
    <!-- Caso: no pertenece a ninguna unidad -->
    <span
      :if={false}
      class="inline-flex items-center gap-1 rounded-md border border-gray-300 bg-white px-2 py-0.5 text-[11px] font-semibold text-gray-600"
      title="No perteneces a esta unidad"
    >
      <i class="fa-solid fa-user-slash text-[12px]"></i>
    </span>

    <!-- Caso: pertenece (usa assigns calculados arriba) -->
    <span
      :if={!is_nil(@status)}
      class="inline-flex items-center gap-1 rounded-md px-2 py-0.5 text-[11px] font-semibold border border-green-200 bg-green-50 text-green-700"
    >
      <i class={"text-[12px] " <> @m_icon}></i> {@m_label}
    </span>
    """
  end

  # ============ HELPERS ============

  defp membership_style(level) do
    case normalize_level(level) do
      :junior ->
        {"Junior", "fa-solid fa-user"}

      :regular ->
        {"Regular", "fa-solid fa-user-check"}

      :senior ->
        {"Senior", "fa-solid fa-user-tie"}

      _ ->
        {"Miembro", "fa-solid fa-user-check"}
    end
  end

  defp normalize_level(nil), do: nil

  defp normalize_level(lvl) when is_binary(lvl) do
    case String.downcase(lvl) do
      "junior" -> :junior
      "regular" -> :regular
      "senior" -> :senior
      _ -> nil
    end
  end

  defp normalize_level(lvl) when is_atom(lvl), do: lvl
  defp normalize_level(_), do: nil

  # ============ RENDER ============

  @impl true
  def render(assigns) do
    ~H"""
    <section class="flex flex-col h-fit">
      <h2 class="text-3xl font-semibold mb-5 flex items-center justify-center">
        <i class="fa-solid fa-sitemap mr-3 text-3xl rotate-180"></i> Navegar
      </h2>

      <.async_result :let={ou_tree} assign={@ou_tree}>
        <:loading>
          <.loading_spinner size="double_large"></.loading_spinner>
        </:loading>

        <:failed :let={_failure}>
          <div class="text-center text-sm text-red-600">
            Ocurrió un error al cargar la información.
          </div>
        </:failed>

        <.ou_visual_tree ou_tree={ou_tree}>
          <:ou_item :let={ou}>
            <.link patch={~p"/app/#{@module}?context=#{ou.ou_id}"} replace>
              <div class="relative">
                <!-- Líneas guía jerárquicas (md+) -->
                <span
                  :if={!is_root?(ou.ou_id)}
                  class="hidden md:block absolute -left-8 top-0 bottom-0 w-px bg-gray-200"
                >
                </span>
                <span
                  :if={!is_root?(ou.ou_id)}
                  class="hidden md:block absolute -left-8 top-1/2 -translate-y-1/2 w-8 h-px bg-gray-200"
                >
                </span>

    <!-- Tarjeta OU -->
                <div class={
                  "cursor-pointer hover:bg-gray-50 px-4 sm:px-5 py-3 rounded-lg my-1 flex flex-row items-center border transition " <>
                  if @context == ou.ou_id, do: "border-2 border-aurora_orange bg-aurora_orange/10", else: "border-gray-200"
                }>
                  <div class="flex flex-col flex-grow min-w-0">
                    <div class="mt-1 flex flex-wrap gap-1.5 sm:gap-2">
                      <.ou_id_badge size="sm" ou_id={ou.ou_id} />
                      <%!-- <.chip icon_class="fa-solid fa-calendar-days">
                        {Timex.lformat!(ou[:created_at], "{relative}", "es", :relative)}
                      </.chip> --%>
                      <.membership_badge status={ou[:membership_status]} />
                    </div>

                    <div
                      class="text-aurora_orange font-bold text-base sm:text-lg truncate flex flex-row items-center"
                      title={ou.ou_name}
                    >
                      {ou.ou_name}
                    </div>
                  </div>

    <!-- Indicador de pertenencia -->
                  <div class="pl-3 sm:pl-5 flex items-center"></div>
                </div>
              </div>
            </.link>
          </:ou_item>
        </.ou_visual_tree>

    <!-- Leyenda -->
        <div class="mx-auto mt-10 flex flex-wrap items-center justify-center gap-2 text-xs text-gray-600 !hidden">
          <span class="inline-flex items-center gap-1">
            <i class="fa-solid fa-calendar-days"></i> Fecha Fundación
          </span>

          <span class="inline-flex items-center gap-1">
            <i class="fa-regular fa-circle-user"></i> Sin unidad
          </span>
           <span class="inline-flex items-center gap-1"><i class="fa-solid fa-user"></i> Junior</span>
          <span class="inline-flex items-center gap-1">
            <i class="fa-solid fa-user-check"></i> Regular
          </span>

          <span class="inline-flex items-center gap-1">
            <i class="fa-solid fa-user-tie"></i> Senior
          </span>
        </div>
      </.async_result>
    </section>
    """
  end
end
