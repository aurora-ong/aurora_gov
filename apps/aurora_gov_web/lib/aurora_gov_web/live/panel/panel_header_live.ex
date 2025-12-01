defmodule AuroraGovWeb.Live.Panel.Header do
  alias AuroraGovWeb.Live.Panel.AppView
  use AuroraGovWeb, :live_component
  alias Phoenix.LiveView.JS

  @impl true
  def update(assigns, socket) do
    IO.inspect(assigns, label: "PanelHeaderComponent Update")

    socket =
      socket
      |> assign(:app_context, assigns.app_context)
      |> assign(:ou, AuroraGov.Context.OUContext.get_ou_by_id(assigns.app_context.current_ou_id))

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <section class="card w-full flex flex-row h-fit justify-center items-center gap-5 px-10 py-6">
      <div class="flex flex-col grow">
        <.ou_id_badge size="lg" ou_id={@ou.ou_id} />
        <h1 class="text-4xl">{@ou.ou_name}</h1>
      </div>

      <div class="flex flex-row gap-3 items-center justify-center h-full">
        <button
          phx-click="open_proposal_create_modal"
          phx-value-proposal_ou_origin={@ou.ou_id}
          phx-target={@myself}
          class="text-lg primary outlined"
        >
          <i class="fa-solid fa-hand text-xl"></i> Gobernar
        </button>

        <button
          phx-click="open_tree_navigator_modal"
          phx-target={@myself}
          class="text-lg primary outlined"
        >
          <i class="fa-solid fa-sitemap text-xl rotate-180"></i> Navegar
        </button>

        <%!-- <button class="justify-center items-center text-lg primary h-full">
          <i class="fa-solid fa-arrow-up text-xl"></i>
        </button>

        <button class="justify-center items-center text-lg primary">
          <i class="fa-solid fa-arrow-down text-xl"></i>
        </button> --%>
      </div>
    </section>
    """
  end

  def show_navigate(js \\ %JS{}) do
    js
    |> JS.toggle_class("hidden", to: "#dropdown")
  end

  @impl true
  def handle_event(
        "open_proposal_create_modal",
        %{"proposal_ou_origin" => proposal_ou_origin},
        socket
      ) do
    app_view = %AppView{
      view_id: "modal-proposal_create",
      view_module: AuroraGovWeb.Live.Panel.ProposalCreate,
      view_options: %{
        modal_size: "quadruple_large"
      },
      view_params: %{
        initial_values: %{
          proposal_ou_origin: proposal_ou_origin
        }
      }
    }

    send(self(), {:open, :app_modal, app_view})

    {:noreply, socket}
  end

  @impl true
  def handle_event("open_tree_navigator_modal", _params, socket) do
    app_view = %AppView{
      view_id: "modal-tree_navigator",
      view_module: AuroraGovWeb.Live.Panel.TreeNavigator,
      view_options: %{
        modal_size: "quadruple_large"
      }
    }

    send(self(), {:open, :app_modal, app_view})

    {:noreply, socket}
  end
end
