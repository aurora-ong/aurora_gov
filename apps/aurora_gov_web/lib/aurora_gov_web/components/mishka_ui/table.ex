defmodule AuroraGovWeb.Components.Table do
  @moduledoc """
  `AuroraGovWeb.Components.Table` is a versatile component for creating customizable tables in a
  Phoenix LiveView application. This module offers a wide range of configurations to tailor table
  presentations, including options for styling, borders, text alignment, padding, and various visual variants.

  It provides components for table structure (`table/1`), headers (`th/1`), rows (`tr/1`), and cells
  (`td/1`). These elements can be easily customized to fit different design requirements,
  such as fixed layouts, border styles, and hover effects.

  By utilizing slots, the module allows for the inclusion of dynamic content in the table's header and
  footer sections, with the ability to embed icons and custom classes for a polished and interactive interface.
  """

  use Phoenix.Component
  use Gettext, backend: AuroraGovWeb.Gettext
  import AuroraGovWeb.Components.Icon, only: [icon: 1]

  @doc """
  Renders a customizable `table` component that supports custom styling for rows, columns,
  and table headers. This component allows for specifying borders, padding, rounded corners,
  and text alignment.

  It also supports fixed layout and various configurations for headers, footers, and cells.

  ## Examples

  ```elixir
  <.table>
    <:header>Name</:header>
    <:header>Age</:header>
    <:header>Address</:header>
    <:header>Email</:header>
    <:header>Job</:header>
    <:header>Action</:header>

    <.tr>
      <.td>Jim Emerald</.td>
      <.td>27</.td>
      <.td>London No. 1 Lake Park</.td>
      <.td>test@mail.com</.td>
      <.td>Frontend Developer</.td>
      <.td><.rating select={3} count={5} /></.td>
    </.tr>

    <.tr>
      <.td>Alex Brown</.td>
      <.td>32</.td>
      <.td>New York No. 2 River Park</.td>
      <.td>alex@mail.com</.td>
      <.td>Backend Developer</.td>
      <.td><.rating select={4} count={5} /></.td>
    </.tr>

    <.tr>
      <.td>John Doe</.td>
      <.td>28</.td>
      <.td>Los Angeles No. 3 Sunset Boulevard</.td>
      <.td>john@mail.com</.td>
      <.td>UI/UX Designer</.td>
      <.td><.rating select={5} count={5} /></.td>
    </.tr>

    <:footer>Total</:footer>
    <:footer>3 Employees</:footer>
  </.table>


  <.table id="users" rows={@users}>
    <:col :let={user} label="id">{user.id}</:col>
    <:col :let={user} label="username">{user.username}</:col>
  </.table>
  ```
  """
  @doc type: :component
  attr :id, :string,
    default: nil,
    doc: "A unique identifier is used to manage state and interaction"

  attr :class, :string, default: nil, doc: "Custom CSS class for additional styling"
  attr :main_wrapper_class, :string, default: nil, doc: "Custom CSS class"
  attr :inner_wrapper_class, :string, default: nil, doc: "Custom CSS class"
  attr :table_wrapper_class, :string, default: nil, doc: "Custom CSS class"
  attr :table_body_class, :string, default: nil, doc: "Custom CSS class"
  attr :variant, :string, default: "base", doc: "Determines the style"
  attr :rounded, :string, default: "", doc: "Determines the border radius"
  attr :padding, :string, default: "small", doc: "Determines padding for items"
  attr :text_size, :string, default: "small", doc: "Determines text size"
  attr :border, :string, default: "extra_small", doc: "Determines border style"
  attr :header_border, :string, default: "", doc: "Sets the border style for the table header"
  attr :rows_border, :string, default: "", doc: "Sets the border style for rows in the table"
  attr :cols_border, :string, default: "", doc: "Sets the border style for columns in the table"
  attr :thead_class, :string, default: nil, doc: "Adds custom CSS classes to the table header"
  attr :footer_class, :string, default: nil, doc: "Adds custom CSS classes to the table footer"
  attr :table_fixed, :boolean, default: false, doc: "Enables or disables the table's fixed layout"
  attr :text_position, :string, default: "left", doc: "Determines the element's text position"
  attr :space, :string, default: "medium", doc: "Determines the table row spaces"

  attr :rest, :global,
    doc:
      "Global attributes can define defaults which are merged with attributes provided by the caller"

  slot :inner_block, required: false, doc: "Inner block that renders HEEx content"

  slot :header do
    attr :class, :any, doc: "Custom CSS class for additional styling"
    attr :icon, :any, doc: "Icon displayed alongside of an item"
    attr :icon_class, :any, doc: "Determines custom class for the icon"
  end

  slot :footer do
    attr :class, :any, doc: "Custom CSS class for additional styling"
    attr :icon, :any, doc: "Icon displayed alongside of an item"
    attr :icon_class, :any, doc: "Determines custom class for the icon"
  end

  attr :rows, :list, default: []
  attr :row_id, :any, default: nil, doc: "the function for generating the row id"
  attr :row_click, :any, default: nil, doc: "the function for handling phx-click on each row"

  attr :row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row before calling the :col and :action slots"

  slot :col, required: false do
    attr :label, :string
    attr :label_class, :string
    attr :class, :string
  end

  slot :action, doc: "the slot for showing user actions in the last table column"

  def table(assigns) do
    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end

    ~H"""
    <div class={["-m-1.5 overflow-x-auto", @main_wrapper_class]}>
      <div class={["p-1.5 min-w-full inline-block align-middle", @inner_wrapper_class]}>
        <div class={[
          "overflow-hidden",
          text_position(@text_position),
          rounded_size(@rounded, @variant),
          text_size(@text_size),
          border_class(@border, @variant),
          padding_size(@padding),
          rows_space(@space, @variant),
          @header_border && header_border(@header_border, @variant),
          @rows_border != "" && rows_border(@rows_border, @variant),
          @cols_border && cols_border(@cols_border, @variant),
          @table_wrapper_class
        ]}>
          <table
            class={[
              "min-w-full",
              @rows != [] && "divide-y",
              @table_fixed && "table-fixed",
              @variant == "separated" || (@variant == "base_separated" && "border-separate"),
              @class
            ]}
            {@rest}
          >
            <thead class={@thead_class}>
              <.tr>
                <.th
                  :for={{header, index} <- Enum.with_index(@header, 1)}
                  id={"#{@id}-table-header-#{index}"}
                  scope="col"
                  class={header[:class]}
                >
                  <.icon
                    :if={header[:icon]}
                    name={header[:icon]}
                    class={["table-header-icon block me-2", header[:icon_class]]}
                  /> {render_slot(header)}
                </.th>
              </.tr>

              <%!-- <.tr :if={@col}>
                <.th :for={col <- @col} class={["font-normal", col[:label_class]]}>{col[:label]}</.th>
                <.th :if={@action != []} class="relative">
                  <span class="sr-only">{gettext("Actions")}</span>
                </.th>
              </.tr> --%>
            </thead>

            <tbody
              id={@id}
              phx-update={match?(%Phoenix.LiveView.LiveStream{}, @rows) && "stream"}
              class={[@rows != [] && "divide-y", @table_body_class]}
              aria-live="polite"
            >
              {render_slot(@inner_block)}
              <.tr :for={row <- @rows} :if={@rows != []} id={@row_id && @row_id.(row)}>
                <.td
                  :for={{col, i} <- Enum.with_index(@col)}
                  phx-click={@row_click && @row_click.(row)}
                  class={col[:class]}
                >
                  {render_slot(col, @row_item.(row))}
                </.td>

                <.td :if={@action} class="relative w-14 p-0">
                  <div class="relative whitespace-nowrap py-4 text-right text-sm font-medium">
                    <span class="absolute -inset-y-px -right-4 left-0" />
                    <span :for={action <- @action} class="relative ml-4 font-semibold leading-6">
                      {render_slot(action, @row_item.(row))}
                    </span>
                  </div>
                </.td>
              </.tr>
            </tbody>

            <tfoot :if={length(@footer) > 0} class={@footer_class}>
              <.tr>
                <.td
                  :for={{footer, index} <- Enum.with_index(@footer, 1)}
                  id={"#{@id}-table-footer-#{index}"}
                  class={footer[:class]}
                >
                  <div class="flex items-center">
                    <.icon
                      :if={footer[:icon]}
                      name={footer[:icon]}
                      class={["table-footer-icon block me-2", footer[:icon_class]]}
                    /> {render_slot(footer)}
                  </div>
                </.td>
              </.tr>
            </tfoot>
          </table>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders a table header cell (`<th>`) component with customizable class and scope attributes.
  This component allows for additional styling and accepts global attributes.

  ## Examples

  ```elixir
  <.th>Column Title</.th>
  ```
  """
  @doc type: :component
  attr :id, :string,
    default: nil,
    doc: "A unique identifier is used to manage state and interaction"

  attr :class, :any, default: nil, doc: "Custom CSS class for additional styling"
  attr :scope, :string, default: nil, doc: "Specifies the scope of the table header cell"

  attr :rest, :global,
    doc:
      "Global attributes can define defaults which are merged with attributes provided by the caller"

  slot :inner_block, required: false, doc: "Inner block that renders HEEx content"

  def th(assigns) do
    ~H"""
    <th id={@id} scope={@scope} class={["table-header", @class]} {@rest}>
      {render_slot(@inner_block)}
    </th>
    """
  end

  @doc """
  Renders a table row (<tr>) component with customizable class attributes.
  This component allows for additional styling and accepts global attributes.

  ## Examples

  ```elixir
  <.tr>
    <.td>Data 1</.td>
    <.td>Data 2</.td>
  </.tr>
  ```
  """
  @doc type: :component
  attr :id, :string,
    default: nil,
    doc: "A unique identifier is used to manage state and interaction"

  attr :class, :string, default: nil, doc: "Custom CSS class for additional styling"

  attr :rest, :global,
    doc:
      "Global attributes can define defaults which are merged with attributes provided by the caller"

  slot :inner_block, required: false, doc: "Inner block that renders HEEx content"

  def tr(assigns) do
    ~H"""
    <tr id={@id} class={["table-row", @class]} {@rest}>
      {render_slot(@inner_block)}
    </tr>
    """
  end

  @doc """
  Renders a table data cell (`<td>`) component with customizable class attributes.
  This component allows for additional styling and accepts global attributes.

  ## Examples
  ```elixir
  <.td>Data</.td>
  ```
  """
  @doc type: :component
  attr :id, :string,
    default: nil,
    doc: "A unique identifier is used to manage state and interaction"

  attr :class, :string, default: nil, doc: "Custom CSS class for additional styling"

  attr :rest, :global,
    doc:
      "Global attributes can define defaults which are merged with attributes provided by the caller"

  slot :inner_block, required: false, doc: "Inner block that renders HEEx content"

  def td(assigns) do
    ~H"""
    <td id={@id} class={["table-data-cell", @class]} {@rest}>
      {render_slot(@inner_block)}
    </td>
    """
  end

  defp rounded_size("extra_small", "separated") do
    [
      "[&_.border-separate_tr_td:first-child]:rounded-s-sm [&_.border-separate_tr_td:first-child]:rounded-s-sm",
      "[&_.border-separate_tr_td:last-child]:rounded-e-sm [&_.border-separate_tr_td:last-child]:rounded-e-sm",
      "[&_.border-separate_tr_th:first-child]:rounded-s-sm [&_.border-separate_tr_th:first-child]:rounded-s-sm",
      "[&_.border-separate_tr_th:last-child]:rounded-e-sm [&_.border-separate_tr_th:last-child]:rounded-e-sm"
    ]
  end

  defp rounded_size("small", "separated") do
    [
      "[&_.border-separate_tr_td:first-child]:rounded-s [&_.border-separate_tr_td:first-child]:rounded-s",
      "[&_.border-separate_tr_td:last-child]:rounded-e [&_.border-separate_tr_td:last-child]:rounded-e",
      "[&_.border-separate_tr_th:first-child]:rounded-s [&_.border-separate_tr_th:first-child]:rounded-s",
      "[&_.border-separate_tr_th:last-child]:rounded-e [&_.border-separate_tr_th:last-child]:rounded-e"
    ]
  end

  defp rounded_size("medium", "separated") do
    [
      "[&_.border-separate_tr_td:first-child]:rounded-s-md [&_.border-separate_tr_td:first-child]:rounded-s-md",
      "[&_.border-separate_tr_td:last-child]:rounded-e-md [&_.border-separate_tr_td:last-child]:rounded-e-md",
      "[&_.border-separate_tr_th:first-child]:rounded-s-md [&_.border-separate_tr_th:first-child]:rounded-s-md",
      "[&_.border-separate_tr_th:last-child]:rounded-e-md [&_.border-separate_tr_th:last-child]:rounded-e-md"
    ]
  end

  defp rounded_size("large", "separated") do
    [
      "[&_.border-separate_tr_td:first-child]:rounded-s-lg [&_.border-separate_tr_td:first-child]:rounded-s-lg",
      "[&_.border-separate_tr_td:last-child]:rounded-e-lg [&_.border-separate_tr_td:last-child]:rounded-e-lg",
      "[&_.border-separate_tr_th:first-child]:rounded-s-lg [&_.border-separate_tr_th:first-child]:rounded-s-lg",
      "[&_.border-separate_tr_th:last-child]:rounded-e-lg [&_.border-separate_tr_th:last-child]:rounded-e-lg"
    ]
  end

  defp rounded_size("extra_large", "separated") do
    [
      "[&_.border-separate_tr_td:first-child]:rounded-s-xl [&_.border-separate_tr_td:first-child]:rounded-s-xl",
      "[&_.border-separate_tr_td:last-child]:rounded-e-xl [&_.border-separate_tr_td:last-child]:rounded-e-xl",
      "[&_.border-separate_tr_th:first-child]:rounded-s-xl [&_.border-separate_tr_th:first-child]:rounded-s-xl",
      "[&_.border-separate_tr_th:last-child]:rounded-e-xl [&_.border-separate_tr_th:last-child]:rounded-e-xl"
    ]
  end

  defp rounded_size("extra_small", "base_separated") do
    [
      "[&_.border-separate_tr_td:first-child]:rounded-s-sm [&_.border-separate_tr_td:first-child]:rounded-s-sm",
      "[&_.border-separate_tr_td:last-child]:rounded-e-sm [&_.border-separate_tr_td:last-child]:rounded-e-sm",
      "[&_.border-separate_tr_th:first-child]:rounded-s-sm [&_.border-separate_tr_th:first-child]:rounded-s-sm",
      "[&_.border-separate_tr_th:last-child]:rounded-e-sm [&_.border-separate_tr_th:last-child]:rounded-e-sm"
    ]
  end

  defp rounded_size("small", "base_separated") do
    [
      "[&_.border-separate_tr_td:first-child]:rounded-s [&_.border-separate_tr_td:first-child]:rounded-s",
      "[&_.border-separate_tr_td:last-child]:rounded-e [&_.border-separate_tr_td:last-child]:rounded-e",
      "[&_.border-separate_tr_th:first-child]:rounded-s [&_.border-separate_tr_th:first-child]:rounded-s",
      "[&_.border-separate_tr_th:last-child]:rounded-e [&_.border-separate_tr_th:last-child]:rounded-e"
    ]
  end

  defp rounded_size("medium", "base_separated") do
    [
      "[&_.border-separate_tr_td:first-child]:rounded-s-md [&_.border-separate_tr_td:first-child]:rounded-s-md",
      "[&_.border-separate_tr_td:last-child]:rounded-e-md [&_.border-separate_tr_td:last-child]:rounded-e-md",
      "[&_.border-separate_tr_th:first-child]:rounded-s-md [&_.border-separate_tr_th:first-child]:rounded-s-md",
      "[&_.border-separate_tr_th:last-child]:rounded-e-md [&_.border-separate_tr_th:last-child]:rounded-e-md"
    ]
  end

  defp rounded_size("large", "base_separated") do
    [
      "[&_.border-separate_tr_td:first-child]:rounded-s-lg [&_.border-separate_tr_td:first-child]:rounded-s-lg",
      "[&_.border-separate_tr_td:last-child]:rounded-e-lg [&_.border-separate_tr_td:last-child]:rounded-e-lg",
      "[&_.border-separate_tr_th:first-child]:rounded-s-lg [&_.border-separate_tr_th:first-child]:rounded-s-lg",
      "[&_.border-separate_tr_th:last-child]:rounded-e-lg [&_.border-separate_tr_th:last-child]:rounded-e-lg"
    ]
  end

  defp rounded_size("extra_large", "base_separated") do
    [
      "[&_.border-separate_tr_td:first-child]:rounded-s-xl [&_.border-separate_tr_td:first-child]:rounded-s-xl",
      "[&_.border-separate_tr_td:last-child]:rounded-e-xl [&_.border-separate_tr_td:last-child]:rounded-e-xl",
      "[&_.border-separate_tr_th:first-child]:rounded-s-xl [&_.border-separate_tr_th:first-child]:rounded-s-xl",
      "[&_.border-separate_tr_th:last-child]:rounded-e-xl [&_.border-separate_tr_th:last-child]:rounded-e-xl"
    ]
  end

  defp rounded_size("extra_small", _), do: "rounded-sm"

  defp rounded_size("small", _), do: "rounded"

  defp rounded_size("medium", _), do: "rounded-md"

  defp rounded_size("large", _), do: "rounded-lg"

  defp rounded_size("extra_large", _), do: "rounded-xl"

  defp rounded_size(params, _) when is_binary(params), do: [params]

  defp text_size("extra_small"), do: "text-xs"
  defp text_size("small"), do: "text-sm"
  defp text_size("medium"), do: "text-base"
  defp text_size("large"), do: "text-lg"
  defp text_size("extra_large"), do: "text-xl"
  defp text_size(params) when is_binary(params), do: [params]

  defp text_position("left"), do: "[&_table]:text-left [&_table_thead]:text-left"
  defp text_position("right"), do: "[&_table]:text-right [&_table_thead]:text-right"
  defp text_position("center"), do: "[&_table]:text-center [&_table_thead]:text-center"
  defp text_position("justify"), do: "[&_table]:text-justify [&_table_thead]:text-justify"
  defp text_position("start"), do: "[&_table]:text-start [&_table_thead]:text-start"
  defp text_position("end"), do: "[&_table]:text-end [&_table_thead]:text-end"
  defp text_position(params) when is_binary(params), do: params

  defp border_class(_, variant)
       when variant in [
              "default",
              "shadow",
              "transparent",
              "stripped",
              "hoverable",
              "separated",
              "base_separated"
            ],
       do: nil

  defp border_class("extra_small", _), do: "border"
  defp border_class("small", _), do: "border-2"
  defp border_class("medium", _), do: "border-[3px]"
  defp border_class("large", _), do: "border-4"
  defp border_class("extra_large", _), do: "border-[5px]"
  defp border_class(params, _) when is_binary(params), do: [params]

  defp cols_border(_, variant)
       when variant in ["default", "shadow", "transparent", "stripped", "hoverable", "separated"],
       do: nil

  defp cols_border("extra_small", _) do
    [
      "[&_table_thead_th:not(:last-child)]:border-e",
      "[&_table_tbody_td:not(:last-child)]:border-e",
      "[&_table_tfoot_td:not(:last-child)]:border-e"
    ]
  end

  defp cols_border("small", _) do
    [
      "[&_table_thead_th:not(:last-child)]:border-e-2",
      "[&_table_tbody_td:not(:last-child)]:border-e-2",
      "[&_table_tfoot_td:not(:last-child)]:border-e-2"
    ]
  end

  defp cols_border("medium", _) do
    [
      "[&_table_thead_th:not(:last-child)]:border-e-[3px]",
      "[&_table_tbody_td:not(:last-child)]:border-e-[3px]",
      "[&_table_tfoot_td:not(:last-child)]:border-e-[3px]"
    ]
  end

  defp cols_border("large", _) do
    [
      "[&_table_thead_th:not(:last-child)]:border-e-4",
      "[&_table_tbody_td:not(:last-child)]:border-e-4",
      "[&_table_tfoot_td:not(:last-child)]:border-e-4"
    ]
  end

  defp cols_border("extra_large", _) do
    [
      "[&_table_thead_th:not(:last-child)]:border-e-[5px]",
      "[&_table_tbody_td:not(:last-child)]:border-e-[5px]",
      "[&_table_tfoot_td:not(:last-child)]:border-e-[5px]"
    ]
  end

  defp cols_border(params, _) when is_binary(params), do: [params]

  defp rows_border(_, variant)
       when variant in ["default", "shadow", "transparent", "stripped", "hoverable", "separated"],
       do: nil

  defp rows_border("none", "base_separated"), do: nil

  defp rows_border("extra_small", "base_separated") do
    [
      "[&_td]:border-y [&_th]:border-y",
      "[&_td:first-child]:border-s [&_th:first-child]:border-s",
      "[&_td:last-child]:border-e [&_th:last-child]:border-e"
    ]
  end

  defp rows_border("small", "base_separated") do
    [
      "[&_td]:border-y-2 [&_th]:border-y-2",
      "[&_td:first-child]:border-s-2 [&_th:first-child]:border-s-2",
      "[&_td:last-child]:border-e-2 [&_th:last-child]:border-e-2"
    ]
  end

  defp rows_border("medium", "base_separated") do
    [
      "[&_td]:border-y-[3px] [&_th]:border-y-[3px]",
      "[&_td:first-child]:border-s-3 [&_th:first-child]:border-s-3",
      "[&_td:last-child]:border-e-3 [&_th:last-child]:border-e-3"
    ]
  end

  defp rows_border("large", "base_separated") do
    [
      "[&_td]:border-y-4 [&_th]:border-y-4",
      "[&_td:first-child]:border-s-4 [&_th:first-child]:border-s-4",
      "[&_td:last-child]:border-e-4 [&_th:last-child]:border-e-4"
    ]
  end

  defp rows_border("extra_large", "base_separated") do
    [
      "[&_td]:border-y-[5px] [&_th]:border-y-[5px]",
      "[&_td:first-child]:border-s-5 [&_th:first-child]:border-s-5",
      "[&_td:last-child]:border-e-5 [&_th:last-child]:border-e-5"
    ]
  end

  defp rows_border("none", _), do: nil
  defp rows_border("extra_small", _), do: "[&_table_tbody]:divide-y"
  defp rows_border("small", _), do: "[&_table_tbody]:divide-y-2"
  defp rows_border("medium", _), do: "[&_table_tbody]:divide-y-[3px]"
  defp rows_border("large", _), do: "[&_table_tbody]:divide-y-4"
  defp rows_border("extra_large", _), do: "[&_table_tbody]:divide-y-[5px]"
  defp rows_border(params, _) when is_binary(params), do: [params]

  defp header_border(_, variant)
       when variant in [
              "default",
              "shadow",
              "transparent",
              "stripped",
              "hoverable",
              "separated",
              "base_separated"
            ],
       do: nil

  defp header_border("extra_small", _), do: "[&_table]:divide-y"
  defp header_border("small", _), do: "[&_table]:divide-y-2"
  defp header_border("medium", _), do: "[&_table]:divide-y-[3px]"
  defp header_border("large", _), do: "[&_table]:divide-y-4"
  defp header_border("extra_large", _), do: "[&_table]:divide-y-[5px]"
  defp header_border(params, _) when is_binary(params), do: [params]

  defp rows_space(_, variant)
       when variant in [
              "default",
              "shadow",
              "transparent",
              "stripped",
              "hoverable",
              "bordered",
              "base",
              "base_hoverable",
              "base_stripped",
              "outline"
            ],
       do: nil

  defp rows_space("extra_small", _), do: "[&_table]:border-spacing-y-0.5"
  defp rows_space("small", _), do: "[&_table]:border-spacing-y-1"
  defp rows_space("medium", _), do: "[&_table]:border-spacing-y-2"
  defp rows_space("large", _), do: "[&_table]:border-spacing-y-3"
  defp rows_space("extra_large", _), do: "[&_table]:border-spacing-y-4"
  defp rows_space(params, _) when is_binary(params), do: [params]

  defp padding_size("extra_small") do
    [
      "[&_table_.table-data-cell]:px-3 [&_table_.table-data-cell]:py-1.5",
      "[&_table_.table-header]:px-3 [&_table_.table-header]:py-1.5"
    ]
  end

  defp padding_size("small") do
    [
      "[&_table_.table-data-cell]:px-4 [&_table_.table-data-cell]:py-2",
      "[&_table_.table-header]:px-4 [&_table_.table-header]:py-2"
    ]
  end

  defp padding_size("medium") do
    [
      "[&_table_.table-data-cell]:px-5 [&_table_.table-data-cell]:py-2.5",
      "[&_table_.table-header]:px-5 [&_table_.table-header]:py-2.5"
    ]
  end

  defp padding_size("large") do
    [
      "[&_table_.table-data-cell]:px-6 [&_table_.table-data-cell]:py-3",
      "[&_table_.table-header]:px-6 [&_table_.table-header]:py-3"
    ]
  end

  defp padding_size("extra_large") do
    [
      "[&_table_.table-data-cell]:px-7 [&_table_.table-data-cell]:py-3.5",
      "[&_table_.table-header]:px-7 [&_table_.table-header]:py-3.5"
    ]
  end

  defp padding_size(params) when is_binary(params), do: params
end
