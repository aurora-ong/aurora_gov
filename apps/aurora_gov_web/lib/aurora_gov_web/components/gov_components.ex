defmodule AuroraGov.Web.Components.AuroraComponents do
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
  use Gettext, backend: AuroraGov.Web.Gettext

  import AuroraGov.Web.Components.Tooltip
  import AuroraGov.Web.Components.Spinner
  import AuroraGov.Web.Components.Progress

  @doc "Componente base para todos los identificadores del sistema"
  attr :id, :string, required: true
  attr :icon, :string, required: true
  attr :title, :string, default: nil
  attr :patch, :string, default: nil
  attr :class, :string, default: ""
  def base_id_badge(assigns) do
    ~H"""
    <%= if @patch do %>
      <.link patch={@patch} replace class={["group flex w-fit items-center gap-2 px-3 py-1.5 bg-white hover:bg-gray-50 border border-gray-200 hover:border-gray-300 rounded-lg shadow-sm transition-all duration-200 cursor-pointer", @class]} title={@title || @id}>
        <i class={[@icon, "text-gray-400 group-hover:text-gray-600 transition-colors"]}></i>
        <span class="font-mono text-xs font-semibold text-gray-600 group-hover:text-gray-900 truncate max-w-[200px]">{@id}</span>
      </.link>
    <% else %>
      <div class={["group flex w-fit items-center gap-2 px-3 py-1.5 bg-white hover:bg-gray-50 border border-gray-200 hover:border-gray-300 rounded-lg shadow-sm transition-all duration-200", @class]} title={@title || @id}>
        <i class={[@icon, "text-gray-400 group-hover:text-gray-600 transition-colors"]}></i>
        <span class="font-mono text-xs font-semibold text-gray-600 group-hover:text-gray-900 truncate max-w-[200px]">{@id}</span>
      </div>
    <% end %>
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
  attr :text, :string, default: "Cargando", doc: "Texto"

  def loading_spinner(assigns) do
    ~H"""
    <span class="text-center flex justify-center items-center w-full h-full py-10 px-20 gap-3">
      <.spinner size={@size} class={"text-aurora_orange " <> @class} />
      <div :if={@text != ""}>
        <h3 class="text-xl font-semibold">{@text}</h3>
      </div>
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
      Gettext.dngettext(AuroraGov.Web.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(AuroraGov.Web.Gettext, "errors", msg, opts)
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
    _total = Enum.count(ou_list)

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

  @doc "Renders a task status badge"
  def task_status_badge(assigns) do
    {color_class, label} =
      case assigns.status do
        :backlog -> {"bg-gray-100 text-gray-700 border-gray-200", "Backlog (Sin Asignar)"}
        :in_progress -> {"bg-amber-50 text-amber-700 border-amber-200", "En Progreso"}
        :review -> {"bg-blue-50 text-blue-700 border-blue-200", "En Revisión"}
        :completed -> {"bg-emerald-50 text-emerald-700 border-emerald-200", "Completada"}
        :cancelled -> {"bg-red-50 text-red-700 border-red-200", "Anulada"}
        _ -> {"bg-gray-50 text-gray-600 border-gray-200", to_string(assigns.status)}
      end

    assigns = assign(assigns, color_class: color_class, label: label)

    ~H"""
    <span class={[
      "px-2.5 py-0.5 rounded-full border font-semibold uppercase tracking-wider text-[10px]",
      @color_class
    ]}>
      {@label}
    </span>
    """
  end

  @doc "Renders a project status badge"
  def project_status_badge(assigns) do
    {color_class, label} =
      case assigns.status do
        :active -> {"bg-emerald-50 text-emerald-700 border-emerald-200", "Activo"}
        :archived -> {"bg-gray-100 text-gray-700 border-gray-200", "Archivado"}
        :completed -> {"bg-blue-50 text-blue-700 border-blue-200", "Completado"}
        _ -> {"bg-gray-50 text-gray-600 border-gray-200", to_string(assigns.status)}
      end

    assigns = assign(assigns, color_class: color_class, label: label)

    ~H"""
    <span class={[
      "px-2.5 py-0.5 rounded-full border font-semibold uppercase tracking-wider text-[10px]",
      @color_class
    ]}>
      {@label}
    </span>
    """
  end

  @doc "Renders a membership rank badge"
  def membership_rank_badge(assigns) do
    {color_class, label} =
      case assigns.rank do
        :junior -> {"bg-blue-50 text-blue-700 border-blue-200", "Junior"}
        :regular -> {"bg-emerald-50 text-emerald-700 border-emerald-200", "Regular"}
        :senior -> {"bg-purple-50 text-purple-700 border-purple-200", "Senior"}
        r -> {"bg-gray-50 text-gray-600 border-gray-200", to_string(r)}
      end

    assigns = assign(assigns, color_class: color_class, label: label)

    ~H"""
    <span class={[
      "px-2.5 py-0.5 rounded-full border font-semibold uppercase tracking-wider text-[10px]",
      @color_class
    ]}>
      {@label}
    </span>
    """
  end

  @doc "Renders a membership status badge"
  def membership_status_badge(assigns) do
    {color_class, label} =
      case assigns.status do
        :active -> {"bg-emerald-50 text-emerald-700 border-emerald-200", "Activo"}
        :suspended -> {"bg-amber-50 text-amber-700 border-amber-200", "Suspendido"}
        :expelled -> {"bg-red-50 text-red-700 border-red-200", "Expulsado"}
        :resigned -> {"bg-gray-100 text-gray-700 border-gray-200", "Renunciado"}
        :deceased -> {"bg-gray-800 text-gray-200 border-gray-600", "Fallecido"}
        s -> {"bg-gray-50 text-gray-600 border-gray-200", to_string(s)}
      end

    assigns = assign(assigns, color_class: color_class, label: label)

    ~H"""
    <span class={[
      "px-2.5 py-0.5 rounded-full border font-semibold uppercase tracking-wider text-[10px]",
      @color_class
    ]}>
      {@label}
    </span>
    """
  end

  @doc "Renders a task ID badge"

  attr :id, :string, required: true
  attr :patch, :string, default: nil
  attr :class, :string, default: ""
  attr :title, :string, default: nil

  def task_id_badge(assigns) do
    ~H"""
    <.base_id_badge
      id={@id}
      icon="fa-solid fa-square-check"
      patch={@patch}
      class={@class}
      title={@title}
    />
    """
  end

  @doc "Renders a project ID badge"

  attr :id, :string, required: true
  attr :patch, :string, default: nil
  attr :class, :string, default: ""
  attr :title, :string, default: nil

  def project_id_badge(assigns) do
    ~H"""
    <.base_id_badge id={@id} icon="fa-regular fa-folder" patch={@patch} class={@class} title={@title} />
    """
  end

  @doc "Renders a ledger ID badge"

  attr :id, :string, required: true
  attr :patch, :string, default: nil
  attr :class, :string, default: ""
  attr :title, :string, default: nil

  def ledger_id_badge(assigns) do
    ~H"""
    <.base_id_badge id={@id} icon="fa-solid fa-wallet" patch={@patch} class={@class} title={@title} />
    """
  end

  @doc "Renders a resource ID badge"

  attr :id, :string, required: true
  attr :patch, :string, default: nil
  attr :class, :string, default: ""
  attr :title, :string, default: nil

  def resource_id_badge(assigns) do
    ~H"""
    <.base_id_badge id={@id} icon="fa-solid fa-cube" patch={@patch} class={@class} title={@title} />
    """
  end

  @doc "Renders an OU ID badge"

  attr :id, :string, required: true
  attr :patch, :string, default: nil
  attr :class, :string, default: ""
  attr :size, :string, default: nil
  attr :title, :string, default: nil

  def ou_id_badge(assigns) do
    ~H"""
    <.base_id_badge
      id={@id}
      icon="fa-solid fa-sitemap rotate-180"
      patch={@patch}
      class={@class}
      title={@title}
    />
    """
  end

  @doc "Renders a Person ID badge"

  attr :id, :string, required: true
  attr :patch, :string, default: nil
  attr :class, :string, default: ""
  attr :size, :string, default: nil
  attr :title, :string, default: nil

  def person_id_badge(assigns) do
    ~H"""
    <.base_id_badge id={@id} icon="fa-regular fa-user" patch={@patch} class={@class} title={@title} />
    """
  end

  @doc "Renders a Proposal ID badge"

  attr :id, :string, required: true
  attr :patch, :string, default: nil
  attr :class, :string, default: ""
  attr :size, :string, default: nil
  attr :title, :string, default: nil

  def proposal_id_badge(assigns) do
    ~H"""
    <.base_id_badge id={@id} icon="fa-solid fa-hand" patch={@patch} class={@class} title={@title} />
    """
  end

  @doc "Renders a Power ID badge"
  attr :id, :string, required: true
  attr :patch, :string, default: nil
  attr :class, :string, default: ""
  attr :size, :string, default: nil
  attr :title, :string, default: nil

  def power_id_badge(assigns) do
    ~H"""
    <.base_id_badge id={@id} icon="fa-solid fa-bolt" patch={@patch} class={@class} title={@title} />
    """
  end
end
