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
      <%= for {field, meta} <- @command_module.fields(), meta[:visible?] do %>
        <div class="mb-4">
          <.input
            field={@form[field]}
            type={meta[:form_type] || :text}
            label={meta[:label]}
            class="w-full"
          />
          <%= if meta[:description] do %>
            <p class="text-sm text-gray-500">{meta[:description]}</p>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end
end
