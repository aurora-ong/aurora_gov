defmodule AuroraGov.Web.Component.DevMessage do
  use Phoenix.Component
  use AuroraGov.Web, :verified_routes

  def dev_panel(assigns) do
    ~H"""
    <!-- Footer -->
    <div class="card w-4/6 flex flex-col h-fit justify-center items-center">
      En desarrollo
    </div>
    """
  end
end
