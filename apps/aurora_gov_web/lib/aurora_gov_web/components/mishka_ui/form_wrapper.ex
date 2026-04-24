defmodule AuroraGov.Web.Components.FormWrapper do
  @moduledoc """
  Componente ligero para envolver formularios.
  """
  use Phoenix.Component

  @doc """
  Renderiza un formulario base.
  """
  attr :for, :any, required: true, doc: "Estructura de datos (Changeset/Conn)"
  attr :as, :any, default: nil, doc: "Nombre del parámetro de servidor"
  attr :id, :string, default: nil

  # Clases CSS
  attr :class, :string, default: nil
  attr :wrapper_class, :string, default: "flex flex-col space-y-5"
  attr :actions_class, :string, default: "mt-6 flex items-center justify-between gap-4"

  attr :rest, :global,
    include: ~w(autocomplete name rel action enctype method novalidate target multipart)

  slot :inner_block, required: true
  slot :actions, required: false

  def form_wrapper(assigns) do
    ~H"""
    <.form :let={f} for={@for} as={@as} id={@id} class={@class} {@rest}>
      <div class={@wrapper_class}>{render_slot(@inner_block, f)}</div>

      <div :if={@actions != []} class={@actions_class}>{render_slot(@actions, f)}</div>
    </.form>
    """
  end

  @doc """
  Wrapper simplificado con estilos por defecto.
  """
  attr :for, :any, required: true
  attr :as, :any, default: nil
  attr :id, :string, default: nil

  # Estilos por defecto (Tailwind)
  attr :class, :string,
    default: "space-y-8 bg-white p-6 rounded-lg shadow-sm border border-gray-100"

  attr :rest, :global

  slot :inner_block, required: true
  slot :actions

  def simple_form(assigns) do
    ~H"""
    <.form_wrapper
      :let={f}
      for={@for}
      as={@as}
      id={@id}
      class={@class}
      {@rest}
    >
      {render_slot(@inner_block, f)}
      <:actions :let={f}>{render_slot(@actions, f)}</:actions>
    </.form_wrapper>
    """
  end
end
