defmodule AuroraGovWeb.PersonLoginLive do
  use AuroraGovWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="mx-auto my-auto max-w-sm">
      <.simple_form for={@form} id="login_form" action={~p"/persons/log_in"} phx-update="ignore">
        <.input field={@form[:id]} type="text" label="Id" required />
        <.input field={@form[:password]} type="password" label="Password" required />

        <:actions>
          <.input field={@form[:remember_me]} type="checkbox" label="Keep me logged in" />
        </:actions>
        <:actions>
          <.button phx-disable-with="Logging in..." class="w-full">
            Log in <span aria-hidden="true">→</span>
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    email = Phoenix.Flash.get(socket.assigns.flash, :email)
    form = to_form(%{"email" => email}, as: "person")
    {:ok, assign(socket, form: form), temporary_assigns: [form: form]}
  end
end
