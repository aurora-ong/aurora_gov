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
    <.button_group class={
      "rounded-lg overflow-hidden shadow-sm bg-gray-100 p-0 gap-0 border border-gray-200 " <>
      @class
    }>
      <%= for {opt, _idx} <- Enum.with_index(@options) do %>
        <.button
          type="button"
          class={
            "transition-colors duration-150 font-semibold px-4 py-2 focus:z-10 focus:outline-none border-0 " <>
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
    </.button_group>
    """
  end
end
