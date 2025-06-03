defmodule AuroraGov.Command do
  defmacro __using__(fields_with_opts) do
    command_fields = for {name, opts} <- fields_with_opts, do: {name, Keyword.get(opts, :type, :string)}

    quote bind_quoted: [command_fields: command_fields, fields_with_opts: fields_with_opts] do
      # Define los campos del comando (Commanded los convierte en defstruct)
      use Commanded.Command, Enum.into(command_fields, %{})

      Module.register_attribute(__MODULE__, :form_fields, accumulate: true)

      for {name, opts} <- fields_with_opts do
        @form_fields {name, opts}
      end

      def fields, do: Enum.into(@form_fields, %{})
    end
  end
end
