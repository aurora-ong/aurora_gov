defmodule AuroraGovWeb.DynamicCommandFormComponent do
  use AuroraGovWeb, :live_component

  @impl true
  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <%= for {field, meta} <- @command_module.fields(), meta[:field_type] == :user do %>
        <div class="mb-4">
          <.input
            field={@form[field]}
            type={meta[:form_type] || :text}
            label={meta[:label]}
            class="w-full"
            description={meta[:description]}
          />
        </div>
      <% end %>
    </div>
    """
  end
end
