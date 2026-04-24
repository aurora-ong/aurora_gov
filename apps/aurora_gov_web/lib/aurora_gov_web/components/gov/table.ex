defmodule AuroraGov.Web.Components.Table do
  use Phoenix.Component
  import AuroraGov.Web.Components.Icon, only: [icon: 1]

  @doc """
  Tabla Versátil con soporte para phx-target (@myself).
  """

  attr :id, :string, required: true
  attr :rows, :list, required: true
  attr :class, :string, default: nil
  attr :loading, :boolean, default: false

  # NUEVO: Target para LiveComponents
  attr :target, :any, default: nil

  # Paginación / Ordenamiento / Totales
  attr :page, :integer, default: 1
  attr :total_pages, :integer, default: 0
  attr :total_count, :integer, default: 0
  attr :sort_by, :any, default: nil
  attr :sort_order, :any, default: :asc

  # Eventos
  attr :on_paginate, :string, default: "paginate"
  attr :on_sort, :string, default: "sort"
  attr :on_row_click, :any, default: nil

  slot :col do
    attr :label, :string
    attr :field, :atom
    attr :class, :string
    attr :align, :string, values: ~w(left center right)
  end

  slot :custom_row
  slot :action
  slot :top_content
  slot :empty_state

  def table(assigns) do
    assigns = assign(assigns, :col_count, length(assigns.col) + if(assigns.action != [], do: 1, else: 0))

    ~H"""
    <div class={["flex flex-col gap-4 relative", @class]}>

      <div :if={@loading} class="absolute inset-0 z-20 flex items-center justify-center bg-white/60 backdrop-blur-[1px] rounded-lg transition-all duration-300">
        <div class="flex flex-col items-center bg-white p-3 rounded-full shadow-lg">
           <i class="fa-solid fa-circle-notch fa-spin text-aurora_orange text-2xl"></i>
        </div>
      </div>

      <div class={["transition-opacity duration-300", @loading && "opacity-50 pointer-events-none select-none"]}>

        <div :if={@top_content} class="px-1 mb-2">
          {render_slot(@top_content)}
        </div>

        <div class="overflow-hidden rounded-lg border border-gray-200 bg-white shadow-sm">
          <div class="overflow-x-auto">
            <table class="min-w-full divide-y divide-gray-200">

              <thead :if={@col != []} class="bg-gray-50">
                <tr>
                  <th :for={col <- @col}
                    class={[
                      "px-6 py-3 text-xs font-medium uppercase tracking-wider text-gray-500",
                      "text-#{Map.get(col, :align, "left")}",
                      col[:field] && "cursor-pointer hover:bg-gray-100 hover:text-gray-700"
                    ]}
                    phx-click={col[:field] && @on_sort}
                    phx-value-field={col[:field]}
                    phx-target={@target}
                  >
                    <div class={["flex items-center gap-1", align_class(Map.get(col, :align, "left"))]}>
                      {col[:label]}
                      <%= if col[:field] && @sort_by == col[:field] do %>
                        <.icon name={if @sort_order == :asc, do: "hero-arrow-up", else: "hero-arrow-down"} class="size-3 text-aurora_orange" />
                      <% end %>
                    </div>
                  </th>
                  <th :if={@action != []} class="px-6 py-3"><span class="sr-only">Acciones</span></th>
                </tr>
              </thead>

              <tbody id={@id} phx-update="stream" class={["divide-y divide-gray-200 bg-white", @total_count == 0 && "hidden"]}>
                <tr
                  :for={{dom_id, item} <- @rows}
                  id={dom_id}
                  class={["group transition-colors hover:bg-gray-50", @on_row_click && "cursor-pointer"]}
                  phx-click={@on_row_click && @on_row_click.(item)}
                  phx-target={@target}
                >
                  <%= if @custom_row != [] do %>
                    {render_slot(@custom_row, item)}
                  <% else %>
                    <td :for={col <- @col} class={["px-6 py-4 whitespace-nowrap text-sm text-gray-700", "text-#{Map.get(col, :align, "left")}", col[:class]]}>
                      {render_slot(col, item)}
                    </td>
                    <td :if={@action != []} class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                      {render_slot(@action, item)}
                    </td>
                  <% end %>
                </tr>
              </tbody>

              <tbody :if={@total_count == 0 && @empty_state != []}>
                <tr>
                  <td colspan={if @col_count > 0, do: @col_count, else: 100} class="px-6 py-12 text-center text-gray-500">
                      {render_slot(@empty_state)}
                  </td>
                </tr>
              </tbody>
            </table>
          </div>

          <div :if={@total_pages > 0} class="border-t border-gray-200 bg-gray-50 px-6 py-3 flex items-center justify-between sm:justify-end gap-4">
            <div class="hidden sm:block text-xs text-gray-500 mr-auto">
               Total: <span class="font-medium text-gray-900">{@total_count}</span> registros.
               Página <span class="font-medium">{@page}</span> de <span class="font-medium">{@total_pages}</span>
            </div>

            <div class="flex items-center gap-2">
              <button disabled={@page <= 1} phx-click={@on_paginate} phx-value-page={@page - 1} phx-target={@target} class="px-3 py-1 text-sm border rounded bg-white hover:bg-gray-100 disabled:opacity-50">Anterior</button>
              <button disabled={@page >= @total_pages} phx-click={@on_paginate} phx-value-page={@page + 1} phx-target={@target} class="px-3 py-1 text-sm border rounded bg-white hover:bg-gray-100 disabled:opacity-50">Siguiente</button>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp align_class("center"), do: "justify-center"
  defp align_class("right"), do: "justify-end"
  defp align_class("left"), do: "justify-start"
  defp align_class(_), do: "justify-start"
end
