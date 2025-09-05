defmodule AuroraGov.Projector.Model.Person do
  use Ecto.Schema

  @primary_key {:person_id, :string, autogenerate: false}
  schema "person_table" do
    field :person_name, :string
    field :person_mail, :string
    field :person_password, :string, virtual: true, redact: true
    field :person_secret, :string, redact: true
    field :created_at, :utc_datetime_usec
    field :updated_at, :utc_datetime_usec
  end
end
