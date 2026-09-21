defmodule AuroraGov.Web.Live.Panel.TreeNavigator do
  use AuroraGov.Web, :live_component
  import AuroraGov.Web.OUVisualTreeComponent
  import AuroraGov.Utils.OUTree

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(:app_context, assigns.app_context)
      |> assign_async(:ou_tree, fn ->
        ou_tree =
          if assigns.app_context.current_person != nil do
            AuroraGov.Context.OUContext.get_ou_tree_with_membership(
              assigns.app_context.current_person.person_id
            )
          else
            AuroraGov.Context.OUContext.list_ou()
            |> Enum.map(&Map.from_struct/1)
          end

        {:ok,
         %{
           ou_tree: ou_tree
         }}
      end)

    {:ok, socket}
  end

  # ============ RENDER ============

  @impl true
  def render(assigns) do
    ~H"""
    <section class="flex flex-col h-fit">
      <h2 class="text-3xl font-semibold mb-5 flex items-center justify-center">
        <i class="fa-solid fa-sitemap mr-3 text-3xl rotate-180"></i> Navegar
      </h2>

      <.async_result :let={ou_tree} assign={@ou_tree}>
        <:loading><.loading_spinner size="double_large" /></:loading>

        <:failed :let={_failure}>
          <div class="text-center text-sm text-red-600">
            Ocurrió un error al cargar la información.
          </div>
        </:failed>

        <.ou_visual_tree ou_tree={ou_tree}>
          <:ou_item :let={ou}>
            <.link patch={~p"/app/#{@app_context.current_module}?context=#{ou.ou_id}"} replace>
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
                  if @app_context.current_ou_id == ou.ou_id, do: "border-2 border-aurora_orange bg-aurora_orange/10", else: "border-gray-200"
                }>
                  <!-- Avatar -->
                  <div class="flex items-center justify-center w-12 h-12 rounded-full overflow-hidden shrink-0 bg-gray-100 border border-gray-200 mr-4">
                    <%= if ou[:ou_avatar_url] do %>
                      <img src={ou.ou_avatar_url} class="w-full h-full object-cover" />
                    <% else %>
                      <i class="fa-solid fa-sitemap text-aurora_orange text-xl rotate-180"></i>
                    <% end %>
                  </div>

                  <div class="flex flex-col grow min-w-0">
                    <div
                      class="text-aurora_orange font-bold text-base sm:text-lg truncate flex flex-row items-center"
                      title={ou.ou_name}
                    >
                      {ou.ou_name}
                    </div>

                    <div class="mt-1 flex flex-wrap gap-1.5 sm:gap-2">
                      <.ou_id_badge size="sm" id={ou.ou_id} />
                      <.membership_rank_badge :if={!is_nil(ou[:membership_rank])} rank={ou[:membership_rank]} />
                    </div>
                  </div>
                  <!-- Indicador de pertenencia -->
                  <div class="pl-3 sm:pl-5 flex items-center"></div>
                </div>
              </div>
            </.link>
          </:ou_item>
        </.ou_visual_tree>
      </.async_result>
    </section>
    """
  end
end
