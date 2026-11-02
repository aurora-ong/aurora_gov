defmodule AuroraGov.Web.Components.ActionDropdown do
  use Phoenix.Component
  alias Phoenix.LiveView.JS

  @doc """
  Renderiza un botón de acciones con menú desplegable (dropdown).
  En pantallas de escritorio muestra el ícono junto con el texto del botón;
  en dispositivos móviles muestra únicamente el ícono para optimizar el espacio,
  desplegando la lista de acciones al presionarlo.

  ## Ejemplo

      <.action_dropdown id="resources-actions">
        <:item
          icon="fa-solid fa-money-bill-transfer"
          label="Nueva Transacción"
          proposal_ou_origin={@app_context.current_ou_id}
          proposal_ou_end={@app_context.current_ou_id}
          proposal_power_id="org.transaction.record"
        />
        <:item
          icon="fa-solid fa-plus"
          label="Nueva Cuenta"
          proposal_ou_origin={@app_context.current_ou_id}
          proposal_ou_end={@app_context.current_ou_id}
          proposal_power_id="org.ledger.create"
        />
      </.action_dropdown>
  """
  attr :id, :string, required: true, doc: "ID único para el componente dropdown"
  attr :label, :string, default: "Acciones", doc: "Texto del botón en escritorio"
  attr :icon, :string, default: "fa-solid fa-bolt", doc: "Ícono del botón principal"
  attr :class, :string, default: "", doc: "Clases CSS adicionales para el contenedor"

  slot :item, required: true, doc: "Cada opción de acción dentro del menú desplegable" do
    attr :icon, :string, doc: "Clase de ícono FontAwesome"
    attr :label, :string, doc: "Etiqueta de la acción"
    attr :on_click, :string, doc: "Evento phx-click (por defecto 'open_proposal_create_modal')"
    attr :phx_target, :any, doc: "Target opcional para el evento"
    attr :proposal_ou_origin, :string, doc: "ID de la OU de origen para la propuesta"
    attr :proposal_ou_end, :string, doc: "ID de la OU de destino para la propuesta"
    attr :proposal_power_id, :string, doc: "ID del poder para la propuesta"
    attr :class, :string, doc: "Clases CSS adicionales para el item"
  end

  def action_dropdown(assigns) do
    ~H"""
    <div id={@id} class={"relative inline-block text-left shrink-0 " <> @class}>
      <button
        type="button"
        phx-click={toggle_dropdown(@id)}
        aria-haspopup="true"
        title={@label}
        class="inline-flex justify-center items-center font-semibold rounded-lg transition-colors focus:outline-none bg-aurora_orange text-white hover:bg-orange-600 border-2 border-transparent shadow text-sm px-2 sm:px-4 py-2 gap-2 cursor-pointer"
      >
        <i class={@icon}></i>
        <span class="hidden sm:inline">{@label}</span>
        <i class="fa-solid fa-chevron-down text-[10px] opacity-80"></i>
      </button>

      <div
        id={"#{@id}-menu"}
        phx-click-away={hide_dropdown(@id)}
        class="hidden absolute right-0 mt-2 w-56 origin-top-right rounded-xl bg-white shadow-xl ring-1 ring-black/5 border border-gray-100 focus:outline-none z-50 py-1.5 divide-y divide-gray-50"
        role="menu"
        aria-orientation="vertical"
      >
        <%= for item <- @item do %>
          <button
            type="button"
            role="menuitem"
            phx-click={
              hide_dropdown(@id)
              |> JS.push(Map.get(item, :on_click, "open_proposal_create_modal"))
            }
            {if item[:phx_target], do: ["phx-target": item[:phx_target]], else: []}
            {if item[:proposal_ou_origin], do: ["phx-value-proposal_ou_origin": item[:proposal_ou_origin]], else: []}
            {if item[:proposal_ou_end], do: ["phx-value-proposal_ou_end": item[:proposal_ou_end]], else: []}
            {if item[:proposal_power_id], do: ["phx-value-proposal_power_id": item[:proposal_power_id]], else: []}
            class={[
              "group flex w-full items-center gap-3 px-4 py-2.5 text-sm font-medium text-gray-700 hover:bg-orange-50 hover:text-aurora_orange transition-colors text-left cursor-pointer",
              item[:class]
            ]}
          >
            <span
              :if={item[:icon]}
              class="w-7 h-7 rounded-lg bg-gray-100 text-gray-500 group-hover:bg-aurora_orange/10 group-hover:text-aurora_orange flex items-center justify-center shrink-0 transition-colors"
            >
              <i class={[item[:icon], "text-xs"]}></i>
            </span>
            <span class="truncate">
              {item[:label] || render_slot(item)}
            </span>
          </button>
        <% end %>
      </div>
    </div>
    """
  end

  defp toggle_dropdown(id) do
    JS.toggle(
      to: "##{id}-menu",
      in:
        {"transition ease-out duration-150", "opacity-0 scale-95 -translate-y-1",
         "opacity-100 scale-100 translate-y-0"},
      out:
        {"transition ease-in duration-100", "opacity-100 scale-100 translate-y-0",
         "opacity-0 scale-95 -translate-y-1"}
    )
  end

  defp hide_dropdown(id) do
    JS.hide(
      to: "##{id}-menu",
      transition:
        {"transition ease-in duration-100", "opacity-100 scale-100 translate-y-0",
         "opacity-0 scale-95 -translate-y-1"}
    )
  end
end
