defmodule AuroraGovWeb.OUVisualTreeComponent do
  use Phoenix.Component

  attr :ou_tree, :list, required: true
  slot :ou_item, required: false

  def ou_visual_tree(assigns) do
    nested_tree = build_nested_tree(assigns.ou_tree)
    assigns = assign(assigns, nested_tree: nested_tree)

    ~H"""
    <div>
      {render_ou_tree(@nested_tree, assigns)}
    </div>
    """
  end

  defp render_ou_tree(tree, assigns) do
    assigns = assign(assigns, :tree, tree)

    ~H"""
    <ul class="list-none">
      <%= for {ou, children} <- @tree do %>
        <li class={if AuroraGov.Utils.OUTree.is_root?(ou.ou_id), do: "", else: "pl-16"}>
          <div>
            <%= if @ou_item != [] do %>
              {render_slot(@ou_item, ou)}
            <% else %>
              <div class="font-semibold">{ou.ou_name}</div>

              <div class="text-sm text-gray-600 mb-1">{ou.ou_goal}</div>
            <% end %>
          </div>

          <%= if map_size(children) > 0 do %>
            {render_ou_tree(children, assigns)}
          <% end %>
        </li>
      <% end %>
    </ul>
    """
  end

  defp build_nested_tree(ous) do
    Enum.reduce(ous, %{}, fn ou, acc ->
      parts = String.split(ou.ou_id, ".")
      insert_in_tree(parts, ou, acc)
    end)
  end

  defp insert_in_tree([_segment], ou, tree), do: Map.put(tree, ou, %{})

  defp insert_in_tree([_head | rest], ou, tree) do
    {parent_key, parent_ou} =
      Enum.find(tree, fn {existing_ou, _} ->
        String.starts_with?(ou.ou_id, existing_ou.ou_id <> ".")
      end) || {nil, nil}

    if parent_key do
      updated_children = insert_in_tree(rest, ou, parent_ou)
      Map.put(tree, parent_key, updated_children)
    else
      Map.put(tree, ou, %{})
    end
  end
end
