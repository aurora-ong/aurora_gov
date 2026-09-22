defmodule AuroraGov.Web.PasswordStrength do
  @moduledoc """
  Evalúa la fuerza de una contraseña para mostrarla en tiempo real en el registro.

  Devuelve `:vacia`, `:debil`, `:buena` o `:fuerte`. El indicador es solo
  informativo: la regla que acepta o rechaza la contraseña sigue siendo
  `AuroraGov.Command.RegisterPerson.handle_validate/1`.

  El largo mínimo declarado aquí replica el de ese comando; si cambia allá,
  cambiar también `@minimum_length`.
  """

  @minimum_length 6

  @common_passwords ~w(
    123456 1234567 12345678 123456789 password passw0rd contraseña
    qwerty qwerty123 abc123 aurora aurora123 auroragov
  )

  @doc """
  Clasifica una contraseña en uno de los cuatro niveles.
  """
  def score(password) when is_binary(password) do
    cond do
      password == "" -> :vacia
      String.length(password) < @minimum_length -> :debil
      String.downcase(password) in @common_passwords -> :debil
      single_character?(password) -> :debil
      String.length(password) >= 12 and character_classes(password) >= 3 -> :fuerte
      character_classes(password) >= 2 -> :buena
      true -> :debil
    end
  end

  def score(_password), do: :vacia

  @doc """
  Largo mínimo usado por el indicador.
  """
  def minimum_length, do: @minimum_length

  defp character_classes(password) do
    [~r/[a-z]/u, ~r/[A-Z]/u, ~r/[0-9]/, ~r/[^a-zA-Z0-9]/u]
    |> Enum.count(&Regex.match?(&1, password))
  end

  defp single_character?(password) do
    password
    |> String.graphemes()
    |> Enum.uniq()
    |> length() == 1
  end
end
