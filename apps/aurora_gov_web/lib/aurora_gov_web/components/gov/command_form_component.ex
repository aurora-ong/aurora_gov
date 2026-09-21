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
              <% :image_upload -> %>
                <% upload_assign = Map.get(@uploads, field_meta.name) %>
                <%= if upload_assign do %>
                  <div class="w-full flex flex-col gap-2">
                    <label class="block text-sm font-semibold leading-6 text-zinc-800">
                      {field_meta.label}
                    </label>
                    <div phx-drop-target={upload_assign.ref} class="border-2 border-dashed border-gray-300 rounded-lg p-6 flex flex-col items-center justify-center bg-gray-50 hover:bg-gray-100 transition relative overflow-hidden">
                      <.live_file_input upload={upload_assign} class="opacity-0 absolute inset-0 w-full h-full cursor-pointer z-10" id={"upload_#{field_meta.name}"} />
                      <div class="flex flex-col items-center gap-2 pointer-events-none">
                        <i class="fa-solid fa-cloud-arrow-up text-3xl text-gray-400"></i>
                        <span class="text-sm text-blue-600 font-medium">Haz click para subir un archivo o arrástralo aquí</span>
                        <span class="text-xs text-gray-500">PNG, JPG, JPEG hasta 5MB</span>
                      </div>
                      
                      <div class="w-full mt-4 z-20 relative">
                        <%= for entry <- upload_assign.entries do %>
                          <div class="flex items-center gap-3 w-full bg-white p-2 rounded border border-gray-200 shadow-sm mb-2">
                            <div class="flex-1 min-w-0">
                              <p class="text-sm font-medium text-gray-900 truncate"><%= entry.client_name %></p>
                              <p class="text-xs text-gray-500"><%= entry.progress %>%</p>
                            </div>
                            <button type="button" phx-click="cancel-upload" phx-value-upload-name={field_meta.name} phx-value-ref={entry.ref} phx-target={@target || nil} class="text-red-500 hover:text-red-700 bg-red-50 p-1.5 rounded">
                              <i class="fa-solid fa-xmark"></i>
                            </button>
                          </div>
                        <% end %>
                      </div>
                    </div>
                    <%= if field_meta.description do %>
                      <p class="text-sm text-gray-500 mt-1">{field_meta.description}</p>
                    <% end %>
                  </div>
                <% end %>
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
