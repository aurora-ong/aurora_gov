defmodule AuroraGov.Web.DynamicCommandFormComponent do
  use AuroraGov.Web, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-4">
      <%= for field_meta <- @command_module.field_definitions() do %>
        <%= if field_meta.source == :user do %>
          <div>
            <%= case field_meta.form_type do %>
              <% :user_search -> %>
                <.live_component
                  module={AuroraGov.Web.Components.SmartInputs.UserSelector}
                  id={"#{field_meta.name}_selector"}
                  form={@form}
                  field={@form[field_meta.name]}
                  label={field_meta.label}
                  app_context={@app_context}
                />
              <% :global_user_search -> %>
                <.live_component
                  module={AuroraGov.Web.Components.SmartInputs.GlobalUserSelector}
                  id={"#{field_meta.name}_selector"}
                  form={@form}
                  field={@form[field_meta.name]}
                  label={field_meta.label}
                  app_context={@app_context}
                />
              <% :ou_search -> %>
                <.live_component
                  module={AuroraGov.Web.Components.SmartInputs.OUSelector}
                  id={"#{field_meta.name}_selector"}
                  form={@form}
                  field={@form[field_meta.name]}
                  label={field_meta.label}
                  app_context={@app_context}
                />
              <% :role_search -> %>
                <.live_component
                  module={AuroraGov.Web.Components.SmartInputs.RoleSelector}
                  id={"#{field_meta.name}_selector"}
                  form={@form}
                  field={@form[field_meta.name]}
                  label={field_meta.label}
                  app_context={@app_context}
                />
              <% :project_search -> %>
                <.live_component
                  module={AuroraGov.Web.Components.SmartInputs.ProjectSelector}
                  id={"#{field_meta.name}_selector"}
                  form={@form}
                  field={@form[field_meta.name]}
                  label={field_meta.label}
                  app_context={@app_context}
                />
              <% :task_search -> %>
                <.live_component
                  module={AuroraGov.Web.Components.SmartInputs.TaskSelector}
                  id={"#{field_meta.name}_selector"}
                  form={@form}
                  field={@form[field_meta.name]}
                  label={field_meta.label}
                  app_context={@app_context}
                  project_id={Map.get(@form.params, "project_id") || Map.get(@form.params, :project_id)}
                />
              <% :resource_selector -> %>
                <.live_component
                  module={AuroraGov.Web.Components.SmartInputs.ResourceSelector}
                  id={"#{field_meta.name}_selector"}
                  form={@form}
                  field={@form[field_meta.name]}
                  label={field_meta.label}
                  filter_by_ou={Keyword.get(field_meta.opts, :filter_by_ou, false)}
                  app_context={@app_context}
                />
              <% :local_resource_selector -> %>
                <.live_component
                  module={AuroraGov.Web.Components.SmartInputs.LocalResourceSelector}
                  id={"#{field_meta.name}_selector"}
                  form={@form}
                  field={@form[field_meta.name]}
                  label={field_meta.label}
                  app_context={@app_context}
                />
              <% :ledger_entries_editor -> %>
                <.live_component
                  module={AuroraGov.Web.Components.SmartInputs.LedgerEntriesEditor}
                  id={"#{field_meta.name}_selector"}
                  form={@form}
                  field={@form[field_meta.name]}
                  label={field_meta.label}
                  app_context={@app_context}
                />
              <% :ledger_selector_origin -> %>
                <.live_component
                  module={AuroraGov.Web.Components.SmartInputs.LedgerSelector}
                  id={"#{field_meta.name}_selector"}
                  form={@form}
                  field={@form[field_meta.name]}
                  label={field_meta.label}
                  app_context={@app_context}
                  ou_id={Map.get(assigns[:proposal_params] || %{}, "proposal_ou_end") || Map.get(assigns[:proposal_params] || %{}, :proposal_ou_end)}
                  resource_id={nil}
                />
              <% :ledger_selector_end -> %>
                <% 
                  origin_acc_id = Map.get(@form.params, "origin_ledger_id") || Map.get(@form.params, :origin_ledger_id)
                  origin_acc = if origin_acc_id && origin_acc_id != "", do: AuroraGov.Context.LedgerContext.get_ledger(origin_acc_id), else: nil
                  inferred_resource_id = if origin_acc, do: origin_acc.resource_id, else: nil
                %>
                <.live_component
                  module={AuroraGov.Web.Components.SmartInputs.LedgerSelector}
                  id={"#{field_meta.name}_selector"}
                  form={@form}
                  field={@form[field_meta.name]}
                  label={field_meta.label}
                  app_context={@app_context}
                  ou_id={Map.get(assigns[:proposal_params] || %{}, "proposal_ou_origin") || Map.get(assigns[:proposal_params] || %{}, :proposal_ou_origin)}
                  resource_id={inferred_resource_id}
                />
              <% type -> %>
                <.input
                  field={@form[field_meta.name]}
                  type={input_type(type)}
                  label={field_meta.label}
                  description={field_meta.description}
                  class="w-full"
                  placeholder={Keyword.get(field_meta.opts, :placeholder)}
                  options={Keyword.get(field_meta.opts, :options, [])}
                />
            <% end %>
          </div>
        <% end %>
      <% end %>
    </div>
    """
  end

  defp input_type(:datetime), do: "datetime-local"
  defp input_type(:utc_datetime), do: "datetime-local"
  defp input_type(:utc_datetime_usec), do: "datetime-local"
  defp input_type(:naive_datetime), do: "datetime-local"
  defp input_type(type), do: Atom.to_string(type)
end
