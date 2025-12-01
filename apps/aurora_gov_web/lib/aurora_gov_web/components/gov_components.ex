
defmodule AuroraGovWeb.Components.AuroraComponents do
  @moduledoc """
  Provides core UI components.

  At first glance, this module may seem daunting, but its goal is to provide
  core building blocks for your application, such as modals, tables, and
  forms. The components consist mostly of markup and are well-documented
  with doc strings and declarative assigns. You may customize and style
  them in any way you want, based on your application growth and needs.

  The default components use Tailwind CSS, a utility-first CSS framework.
  See the [Tailwind CSS documentation](https://tailwindcss.com) to learn
  how to customize them or feel free to swap in another framework altogether.

  Icons are provided by [heroicons](https://heroicons.com). See `icon/1` for usage.
  """

  use Phoenix.Component
  use Gettext, backend: AuroraGovWeb.Gettext

  import AuroraGovWeb.Components.Tooltip
  import AuroraGovWeb.Components.Clipboard
  import AuroraGovWeb.Components.Spinner
  import AuroraGovWeb.Components.Progress

  attr :ou_id, :string, required: true
  attr :size, :string, default: "md"
  attr :ou_name, :string, default: nil

  def ou_id_badge(assigns) do
    size_classes = %{
      "sm" => "text-xs px-1.5 py-0.5",
      "md" => "text-sm px-2 py-0.5",
      "lg" => "text-base px-3 py-1",
      "xl" => "text-lg px-4 py-1.5"
    }

    classes =
      "text-white w-fit bg-black font-semibold rounded cursor-pointer " <>
        Map.get(size_classes, assigns.size, size_classes["md"])

    assigns = assign(assigns, :classes, classes)

    ~H"""
    <.clipboard
      text={@ou_id}
      show_status_text={false}
      class={@classes}
      text_description={@ou_name || @ou_id}
    >
      <:trigger>
        <div class="flex justify-center items-center flex-row gap-1.5">
          <i class={"fa-solid fa-sitemap rotate-180 font-normal "<> "text-#{assigns.size}"}></i>
          <span>{@ou_id}</span>
        </div>
      </:trigger>
       <.tooltip :if={@ou_name} text={@ou_name} />
    </.clipboard>
    """
  end

  @doc """
  Muestra un spinner de carga animado.

  ## Ejemplo

      <.spinner color="orange" size="quadruple_large" />

  ### Colores soportados
  - "black"
  - "orange"
  - "white"
  - "gray"

  ### Tamaños soportados
  - "small"
  - "medium"
  - "large"
  - "quadruple_large"
  """
  attr :size, :string, default: "medium", doc: "Tamaño: small | medium | large | quadruple_large"
  attr :class, :string, default: "", doc: "Clases CSS adicionales"

  def loading_spinner(assigns) do
    ~H"""
    <span class="text-center flex justify-center items-center w-full h-full py-10 px-20">
      <.spinner size={@size} class={"text-aurora_orange " <> @class} />
    </span>
    """
  end



  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    # When using gettext, we typically pass the strings we want
    # to translate as a static argument:
    #
    #     # Translate the number of files with plural rules
    #     dngettext("errors", "1 file", "%{count} files", count)
    #
    # However the error messages in our forms and APIs are generated
    # dynamically, so we need to translate them by calling Gettext
    # with our gettext backend as first argument. Translations are
    # available in the errors.po file (as we use the "errors" domain).
    if count = opts[:count] do
      Gettext.dngettext(AuroraGovWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(AuroraGovWeb.Gettext, "errors", msg, opts)
    end
  end

  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end

  @doc """
  Botón de acción con ícono, tooltip y soporte para tamaños y estado activado/desactivado.

  ## Ejemplo
      <.action_button size="md" active={true} icon_class="fa-solid fa-hand" tooltip_text="Agregar miembro">Nuevo miembro</.action_button>
  """
  attr :size, :string, default: "md", doc: "Tamaño: sm | md | lg | xl"
  attr :active, :boolean, default: true, doc: "Si el botón está activado"
  attr :icon_class, :string, default: "fa-solid fa-hand", doc: "Clase del ícono FontAwesome"
  attr :tooltip_text, :string, default: nil, doc: "Texto del tooltip (opcional)"
  attr :class, :string, default: nil, doc: "Clases CSS adicionales"
  attr :rest, :global
  slot :inner_block, required: true

  def action_button(assigns) do
    size_classes = %{
      "sm" => "text-xs px-2 py-1 gap-1",
      "md" => "text-sm px-3 py-1.5 gap-1.5",
      "lg" => "text-base px-4 py-2 gap-2",
      "xl" => "text-lg px-6 py-3 gap-2.5"
    }

    icon_size_classes = %{
      "sm" => "text-base",
      "md" => "text-lg",
      "lg" => "text-xl",
      "xl" => "text-2xl"
    }

    assigns =
      assign(
        assigns,
        :btn_classes,
        [
          "inline-flex items-center font-semibold rounded-lg transition-colors duration-150 focus:outline-none focus:ring-2 focus:ring-aurora_orange",
          size_classes[assigns.size] || size_classes["md"],
          (assigns.active && "bg-aurora_orange text-white hover:bg-black") ||
            "bg-gray-300 text-gray-500 cursor-not-allowed opacity-60",
          assigns.class
        ]
      )

    assigns =
      assign(
        assigns,
        :icon_size_class,
        icon_size_classes[assigns.size] || icon_size_classes["md"]
      )

    ~H"""
    <.tooltip :if={@tooltip_text} text={@tooltip_text}>
      <button class={@btn_classes} disabled={!@active} type="button" {@rest}>
        <i class={[@icon_class, @icon_size_class]}></i> <span>{render_slot(@inner_block)}</span>
      </button>
    </.tooltip>

    <button :if={!@tooltip_text} class={@btn_classes} disabled={!@active} type="button" {@rest}>
      <i class={[@icon_class, @icon_size_class]}></i> <span>{render_slot(@inner_block)}</span>
    </button>
    """
  end

  @doc """
  Muestra el estado simple de la votación combinando todos los ou_id en una sola barra.
  El tooltip muestra el detalle por ou_id.
  """
  attr :voting_map, :map, required: true, doc: "Mapa de estado de votación por ou_id"
  attr :class, :string, default: ""

  def voting_progress_simple(assigns) do
    total_required =
      Enum.reduce(assigns.voting_map, 0, fn {_ou, v}, acc -> acc + (v[:required_score] || 0) end)

    total_score =
      Enum.reduce(assigns.voting_map, 0, fn {_ou, v}, acc -> acc + (v[:current_score] || 0) end)

    percent =
      if total_required > 0, do: min(100, round(total_score * 100 / total_required)), else: 100

    tooltip_content =
      assigns.voting_map
      |> Enum.map(fn {ou, v} ->
        "<b>#{ou}</b>: #{v[:current_score]} / #{v[:required_score]} (#{v[:total_voters]} votantes)"
      end)
      |> Enum.join("<br>")

    assigns = assign(assigns, :percent, percent)
    assigns = assign(assigns, :tooltip_content, tooltip_content)

    ~H"""
    <.progress size="large my-3 bg-gray-200">
      <.progress_section class="bg-orange-600" value={80}>
        <:tooltip label={"#{@percent}%"} position="top" class="font-bold">
          <span class="text-xs" phx-no-format phx-no-format:raw><%= @tooltip_content %></span>
        </:tooltip>
      </.progress_section>
    </.progress>

    <%!-- <.progress class={@class <> "w-96 h-8"}>
      <.progress_section class="bg-orange-600 text-white" value={@percent}>
        <:tooltip label={"#{@percent}%"} position="top" class="font-bold">
          <span class="text-xs" phx-no-format phx-no-format:raw><%= @tooltip_content %></span>
        </:tooltip>
      </.progress_section>
    </.progress> --%>
    """
  end

  @doc """
  Muestra el estado completo de la votación, una barra por cada ou_id.
  El tooltip de cada sección muestra el detalle de ese ou_id.
  """
  attr :voting_map, :map, required: true, doc: "Mapa de estado de votación por ou_id"
  attr :class, :string, default: ""

  def voting_progress_full(assigns) do
    ou_list = Map.keys(assigns.voting_map)
    total = Enum.count(ou_list)

    color_list = [
      "bg-aurora_orange text-white",
      "bg-black text-white",
      "bg-gray-400 text-black",
      "bg-aurora_blue text-white"
    ]

    assigns = assign(assigns, :ou_list, ou_list)
    assigns = assign(assigns, :color_list, color_list)

    ~H"""
    <.progress class={@class <> " w-96 h-8"}>
      <%= for {ou, idx} <- Enum.with_index(@ou_list) do %>
        <% v = @voting_map[ou] %> <% percent =
          if v[:required_score] > 0,
            do: min(100, round(v[:current_score] * 100 / v[:required_score])),
            else: 0 %>
        <.progress_section class={Enum.at(@color_list, rem(idx, length(@color_list)))} value={percent}>
          <:tooltip label={ou} position="top" class="font-bold">
            <span class="text-xs">
              Puntaje: <b>{v[:current_score]}</b>
              / <b>{v[:required_score]}</b>
              ({v[:total_voters]} votantes)
            </span>
          </:tooltip>
        </.progress_section>
      <% end %>
    </.progress>
    """
  end


end
