defmodule AuroraGov.Command.StartMembership do
  use Commanded.Command,
    ou_id: :string,
    person_id: :string

  def description, do: "Inicia una membresía de una persona en la unidad objetivo"

  def fields do
    %{
      person_id: %{
        label: "Identificador persona",
        description: "Identificador de la persona que se unirá a la unidad objetivo",
        type: :text,
        visible?: true
      },
    }
  end
end
