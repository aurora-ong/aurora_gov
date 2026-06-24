defmodule AuroraGov.GovPower.Field do
  defstruct [:name, :type, :label, :description, :form_type, :source, opts: []]
end

defmodule AuroraGov.GovPower do
  @enforce_keys [:id, :name]

  defstruct [:id, :name, :description, :module, :category, version: 1, status: :active]
end

defmodule AuroraGov.Command do
  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      use Ecto.Schema
      import Ecto.Changeset

      @gov_power_meta Keyword.get(opts, :gov_power, [])
      @fields_config Keyword.fetch!(opts, :fields)

      @primary_key false
      embedded_schema do
        for {name, config} <- @fields_config do
          type = Keyword.get(config, :command_type, :string)
          field name, type
        end
      end

      @compiled_fields Enum.map(@fields_config, fn {name, config} ->
                         %AuroraGov.GovPower.Field{
                           name: name,
                           type: Keyword.get(config, :command_type, :string),
                           label: Keyword.get(config, :label, name |> to_string() |> String.replace("_", " ") |> String.capitalize()),
                           description: Keyword.get(config, :description),
                           form_type: Keyword.get(config, :form_type, :text),
                           source: Keyword.get(config, :source, :user),
                           opts: config
                         }
                       end)

      def new(user_params \\ %{}, opts \\ []) do
        params = Enum.into(user_params, %{})
        context = Keyword.get(opts, :context, %{})

        enriched_params =
          Enum.reduce(@fields_config, params, fn {field_name, config}, acc ->
            source = Keyword.get(config, :source, :user)
            field_string = Atom.to_string(field_name)

            case source do
              {:context, context_key} ->
                value = Map.get(context, context_key) || Map.get(context, to_string(context_key))

                if value do
                  Map.put(acc, field_string, value)
                else
                  acc
                end

              :auto ->
                if field_name == :timestamp do
                  Map.put(acc, field_string, DateTime.utc_now())
                else
                  acc
                end

              _ ->
                acc
            end
          end)

        allowed_keys = Enum.map(@compiled_fields, & &1.name)

        %__MODULE__{}
        |> cast(enriched_params, allowed_keys)
        |> handle_validate(opts)
      end

      def handle_validate(changeset, _opts), do: handle_validate(changeset)
      def handle_validate(changeset), do: changeset

      defoverridable handle_validate: 1, handle_validate: 2

      def gov_power do
        @gov_power_meta
        |> Keyword.put(:module, __MODULE__)
        |> then(&struct!(AuroraGov.GovPower, &1))
      end

      def field_definitions, do: @compiled_fields
    end
  end
end
