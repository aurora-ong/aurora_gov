defmodule AuroraGov.Web.DynamicCommandFormComponent do
  use AuroraGov.Web, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-4">
      <%= for field_meta <- @command_module.field_definitions() do %>
        <%= if field_meta.source == :user do %>
          <div>
            <%= case field_meta.form_type do %>
              <% :user_search -> %>
                <.live_component
                  module={AuroraGov.Web.Components.SmartInputs.UserSelector}
                  id={"#{field_meta.name}_selector"}
                  form={@form}
                  field={field_meta.name}
                  label={field_meta.label}
                />
              <% :ou_search -> %>
                <.live_component
                  module={AuroraGov.Web.Components.SmartInputs.OUSelector}
                  id={"#{field_meta.name}_selector"}
                  form={@form}
                  field={field_meta.name}
                  label={field_meta.label}
                />
              <% type -> %>
                <.input
                  field={@form[field_meta.name]}
                  type={Atom.to_string(type)}
                  label={field_meta.label}
                  description={field_meta.description}
                  class="w-full"
                  placeholder={Keyword.get(field_meta.opts, :placeholder)}
                />
            <% end %>
          </div>
        <% end %>
      <% end %>
    </div>
    """
  end
end
