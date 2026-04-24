defmodule AuroraGov.Web.Components.Badge do
  use Phoenix.Component
  alias Phoenix.LiveView.JS
  import AuroraGov.Web.Components.Icon, only: [icon: 1]

  attr :id, :string, default: nil
  attr :size, :string, default: "sm", values: ~w(xs sm md lg xl)
  attr :icon, :string, default: nil
  attr :icon_pos, :string, default: "left", values: ~w(left right)
  attr :class, :string, default: "bg-gray-100 text-gray-800"

  # Atributos de Enlace (Nuevos)
  attr :navigate, :string, default: nil
  attr :patch, :string, default: nil
  attr :href, :string, default: nil
  attr :method, :string, default: "get"
  attr :target, :string, default: "_self"

  # Indicadores
  attr :indicator, :boolean, default: false
  attr :indicator_class, :string, default: "bg-current"
  attr :indicator_animate, :boolean, default: false

  # Dismiss
  attr :dismiss, :boolean, default: false
  attr :on_dismiss, :any, default: nil

  slot :inner_block, required: true

  def badge(assigns) do
    # Determinamos si es un link verificando si alguno de los atributos de navegación está presente
    is_link = assigns.navigate || assigns.patch || assigns.href
    assigns = assign(assigns, :is_link, is_link)

    ~H"""
    <%= if @is_link do %>
      <.link
        navigate={@navigate}
        patch={@patch}
        href={@href}
        method={@method}
        target={@target}
        class={[
          "inline-flex items-center justify-center font-medium rounded transition-opacity hover:opacity-80 cursor-pointer",
          size_classes(@size),
          @class
        ]}
        id={@id}
      >
        <.badge_content
          icon={@icon}
          icon_pos={@icon_pos}
          indicator={@indicator}
          indicator_class={@indicator_class}
          indicator_animate={@indicator_animate}
          dismiss={@dismiss}
          on_dismiss={@on_dismiss}
          id={@id}
          size={@size}
        >
          <%= render_slot(@inner_block) %>
        </.badge_content>
      </.link>
    <% else %>
      <span
        id={@id}
        class={[
          "inline-flex items-center justify-center font-medium rounded",
          size_classes(@size),
          @class
        ]}
      >
        <.badge_content
          icon={@icon}
          icon_pos={@icon_pos}
          indicator={@indicator}
          indicator_class={@indicator_class}
          indicator_animate={@indicator_animate}
          dismiss={@dismiss}
          on_dismiss={@on_dismiss}
          id={@id}
          size={@size}
        >
          <%= render_slot(@inner_block) %>
        </.badge_content>
      </span>
    <% end %>
    """
  end

  # Extrajimos el contenido interno a una función privada para no repetir código
  defp badge_content(assigns) do
    ~H"""
    <span :if={@indicator} class={[
      "rounded-full mr-1.5",
      indicator_size(@size),
      @indicator_animate && "animate-pulse",
      @indicator_class
    ]} />

    <.icon :if={@icon && @icon_pos == "left"} name={@icon} class="mr-1.5 size-3.5" />

    <%= render_slot(@inner_block) %>

    <.icon :if={@icon && @icon_pos == "right"} name={@icon} class="ml-1.5 size-3.5" />

    <button
      :if={@dismiss}
      type="button"
      class="ml-1.5 inline-flex items-center justify-center rounded-sm opacity-50 hover:opacity-100 focus:outline-none z-10"
      phx-click={@on_dismiss || hide_badge("##{@id}")}
      data-cancel-link
    >
      <.icon name="hero-x-mark" class="size-3.5" />
    </button>
    """
  end

  # Mapeo de tamaños (Padding y Texto)
  defp size_classes("xs"), do: "px-2 py-0.5 text-xs"
  defp size_classes("sm"), do: "px-2.5 py-0.5 text-xs"
  defp size_classes("md"), do: "px-2.5 py-1 text-sm"
  defp size_classes("lg"), do: "px-3 py-1.5 text-sm"
  defp size_classes("xl"), do: "px-3.5 py-2 text-base"

  defp indicator_size("xs"), do: "size-1"
  defp indicator_size("sm"), do: "size-1.5"
  defp indicator_size(_), do: "size-2"

  def hide_badge(selector) do
    JS.hide(to: selector, transition: "fade-out", time: 200)
  end
end
