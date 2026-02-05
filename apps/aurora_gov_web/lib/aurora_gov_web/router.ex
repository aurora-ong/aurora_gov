defmodule AuroraGov.Web.Router do
  use AuroraGov.Web, :router

  import AuroraGov.Web.Auth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {AuroraGov.Web.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_person
  end

  # Enable Swoosh mailbox preview in development
  if Application.compile_env(:aurora_gov_web, :dev_routes) do
    scope "/dev" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  scope "/", AuroraGov.Web do
    pipe_through :browser

    get "/", PageController, :home
    get "/install", PageController, :install
  end

  ## Authentication routes

  scope "/", AuroraGov.Web do
    pipe_through [:browser, :redirect_if_person_is_authenticated]

    live_session :redirect_if_person_is_authenticated,
      on_mount: [{AuroraGov.Web.Auth, :redirect_if_person_is_authenticated}] do
      live "/persons/log_in", PersonLoginLive, :new
      live "/persons/register", PersonRegisterLive
    end

    post "/persons/log_in", PersonSessionController, :create
  end

  scope "/app", AuroraGov.Web do
    pipe_through [:browser, :require_authenticated_person]
  end

  scope "/", AuroraGov.Web do
    pipe_through [:browser]

    delete "/persons/log_out", PersonSessionController, :delete
  end

  scope "/app", AuroraGov.Web do
    pipe_through [:browser]

    live_session :panel,
      on_mount: [
        {AuroraGov.Web.Auth, :mount_current_person}
      ] do
      live "/", Live.Panel, :index
      live "/:module", Live.Panel, :module
    end
  end
end
