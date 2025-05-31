defmodule AuroraGovWeb.PanelOUTreeComponent do
  use AuroraGovWeb, :live_component

  alias Phoenix.LiveView.JS

  def update(assigns, socket) do
    socket =
      socket
      |> assign(:context, assigns.context)
      |> assign(:module, assigns.app_module)
      |> assign(:ou_list, AuroraGov.Projector.OU.get_all_ou())

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <section class="w-full flex flex-col h-fit">
      <h1 class="text-4xl text-black mb-10">Navegar estructura</h1>
      <div class="flex flex-col grow gap-1.5">
        <%= for ou <- @ou_list do %>
          <.link
            patch={~p"/app/#{@module}?context=#{ou.ou_id}"}
            replace
            class={
              if @context == ou.ou_id,
                do: "flex flex-col grow bg-aurora_orange rounded-lg px-5 py-2",
                else: "flex flex-col grow bg-slate-500 rounded-lg px-5 py-2"
            }
          >
            <h2 class="w-fit text-black font-bold rounded"><%= ou.ou_id %></h2>

            <h1 class="text-lg"><%= ou.ou_name %></h1>
          </.link>
        <% end %>
      </div>
    </section>
    """
  end

  def show_navigate(js \\ %JS{}) do
    js
    |> JS.toggle_class("hidden", to: "#dropdown")
  end
end
