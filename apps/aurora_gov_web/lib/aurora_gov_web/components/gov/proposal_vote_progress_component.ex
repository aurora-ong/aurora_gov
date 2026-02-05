defmodule AuroraGov.Web.Components.ProposalVoteProgress do
  use Phoenix.Component
  import AuroraGov.Web.Components.Progress

  @doc """
  Renderiza un grupo de botones para filtros de tabla, usando los colores aurora_orange, negro y gris.

  ## Ejemplo

      <.filter_button_group
        options=[
          %{label: "Todos", value: :all},
          %{label: "Activos", value: :active},
          %{label: "Inactivos", value: :inactive}
        ]
        selected=:all
        on_select={fn value -> ... end}
      />
  """
  attr :current_score, :integer, required: true, doc: "Puntaje actual"
  attr :required_score, :integer, required: true, doc: "Puntaje requerido"

  def proposal_vote_progress(assigns) do
    ~H"""
    <.progress size="medium">
      <.progress_section class={bar_color(@current_score, @required_score)} value={bar_value(@current_score, @required_score)}>
        <:label class="font-bold">
          {@current_score} / {@required_score}
        </:label>
      </.progress_section>
    </.progress>
    """
  end

  defp bar_color(current_score, required_score) do
    cond do
      current_score == required_score -> "bg-green-600 text-white"
      current_score == 0 -> "bg-gray-200 text-black"
      current_score > 0 -> "bg-green-600 text-white"
      current_score < 0 -> "bg-red-600 text-white"
      true -> "bg-yellow-600 text-white"
    end
  end

  defp bar_value(current_score, required_score) do
    cond do
      current_score >= required_score -> 100
      current_score <= 0 -> 100
      true -> round((current_score / required_score) * 100)
    end
  end
end
