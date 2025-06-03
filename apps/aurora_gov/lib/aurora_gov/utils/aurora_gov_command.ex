defmodule AuroraGov.Command do
  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      fields = Keyword.fetch!(opts, :fields)
      meta = Keyword.get(opts, :gov_power, [])

      # Definir el struct del comando
      field_names = Keyword.keys(fields)
      field_types = for {k, v} <- fields, do: {k, Keyword.get(v, :type, :string)}

      use Commanded.Command, Enum.into(field_types, %{})

      Module.register_attribute(__MODULE__, :form_fields, accumulate: true)
      for {name, meta} <- fields, do: @form_fields {name, meta}

      def fields, do: Enum.into(@form_fields, %{})

      @gov_power meta

      def gov_power do
        %{
          id: Keyword.fetch!(@gov_power, :id),
          name: Keyword.fetch!(@gov_power, :name),
          description: Keyword.fetch!(@gov_power, :description)
        }
      end
    end
  end
end
