defmodule AuroraGov.Command.CreateOU do
  alias AuroraGov.Utils.OUTree

  use AuroraGov.Command,
    gov_power: [
      id: "org.ou.create",
      name: "Crear unidad organizacional",
      description: "Permite crear una unidad organizacional",
      category: :ou
    ],
    fields: [
      ou_slug: [
        command_type: :string,
        label: "Identificador de la unidad",
        form_type: :text,
        source: :user,
        description: "Identificador único de la unidad organizacional."
      ],
      ou_id: [
        command_type: :string,
        source: :auto
      ],
      ou_name: [
        command_type: :string,
        label: "Nombre de la unidad",
        form_type: :text,
        source: :user
      ],
      ou_goal: [
        command_type: :string,
        label: "Objetivo de la unidad",
        form_type: :text,
        source: :user
      ],
      ou_description: [
        command_type: :string,
        label: "Descripción de la unidad",
        form_type: :textarea,
        source: :user
      ]
    ]

  def handle_validate(changeset, opts) do
    context = Keyword.get(opts, :context, %{})
    parent_id = Map.get(context, :end_ou_id)

    changeset
    |> validate_required([:ou_slug, :ou_name, :ou_goal, :ou_description])
    |> validate_length(:ou_name, min: 3, max: 30)
    |> validate_hierarchy(parent_id)
    |> build_full_ou_id(parent_id)
  end

  defp validate_hierarchy(changeset, parent_id) do
    validate_change(changeset, :ou_slug, fn :ou_slug, slug ->
      cond do
        not OUTree.valid_slug?(slug) ->
          [ou_slug: "Formato inválido. Solo minúsculas, números y guiones bajos."]

        parent_id && not OUTree.id_valid?(OUTree.join(parent_id, slug)) ->
          [ou_slug: "El ID es inválido o demasiado largo."]

        true ->
          []
      end
    end)
  end

  defp build_full_ou_id(changeset, nil), do: changeset

  defp build_full_ou_id(changeset, parent_id) do
    case get_change(changeset, :ou_slug) do
      nil ->
        changeset

      slug ->
        full_id = OUTree.join(parent_id, slug)
        put_change(changeset, :ou_id, full_id)
    end
  end
end
