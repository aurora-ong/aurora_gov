defmodule AuroraGov.Web.PageController do
  use AuroraGov.Web, :controller

  def home(conn, _params) do
    redirect(conn, to: "/app")
  end

  def install(conn, _params) do
    render(conn, :install, layout: false)
  end
end
