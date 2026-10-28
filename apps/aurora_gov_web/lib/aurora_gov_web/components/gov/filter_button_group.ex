defmodule AuroraGov.Web.Components.FilterButtonGroup do
  use Phoenix.Component
  import AuroraGov.Web.Components.Button

  @doc """
  Renderiza un grupo de botones para filtros de tabla, usando los colores aurora_orange, negro y gris.

  ## Ejemplo

      <.filter_button_group
        options=[
          %{label: "Todos", value: :all},
          %{label: "Activos", value: :active},
          %{label: "Inactivos", value: :inactive}
        ]
        selected=:all
        on_select={fn value -> ... end}
      />
  """
  attr :options, :list, required: true, doc: "Lista de %{label, value} para los botones"
  attr :selected, :any, required: true, doc: "Valor seleccionado"
  attr :on_select, :any, required: true, doc: "Función o evento a disparar al seleccionar"
  attr :class, :string, default: "", doc: "Clases CSS adicionales"
  attr :phx_target, :any, default: nil, doc: "Target opcional para el evento phx-click"

  def filter_button_group(assigns) do
    ~H"""
      <div
        role="group"
        aria-label="Filtros"
                class={
          "flex w-full min-w-0 flex-wrap gap-2 " <>
            @class
        }
      >
        <%= for {opt, _idx} <- Enum.with_index(@options) do %>
        <.button
          type="button"
          class={
            "min-w-0 max-w-full flex-auto sm:flex-none rounded-lg whitespace-normal transition-colors duration-150 !font-medium !text-sm px-3 py-2 sm:px-4 focus:z-10 border-0 " <>
            if(@selected == opt.value,
              do: " bg-aurora_orange! text-white",
              else: "bg-gray-400 text-black hover:bg-gray-500 hover:text-white"
            )
          }
          phx-click={@on_select}
          phx-value-filter={opt.value}
          {if @phx_target, do: ["phx-target": @phx_target], else: []}
        >
          {opt.label}
        </.button>
      <% end %>
    </div>
    """
  end
end
