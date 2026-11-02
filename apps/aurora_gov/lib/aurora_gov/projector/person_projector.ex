defmodule AuroraGov.Projector.PersonProjector do
  alias AuroraGov.Event.PersonRegistered
  alias AuroraGov.Projector.Model.Person

  def project(
        %PersonRegistered{
          person_id: person_id,
          person_name: person_name,
          person_mail: person_mail,
          person_secret: person_secret
        },
        metadata,
        multi
      ) do
    projection = %Person{
      person_id: person_id,
      person_name: person_name,
      person_mail: person_mail,
      person_secret: person_secret,
      created_at: metadata.created_at,
      updated_at: metadata.created_at
    }

    multi
    |> Ecto.Multi.insert(:person_table, projection)
    |> Ecto.Multi.run(:projector_update, fn _repo, %{person_table: registered_person} ->
      {:ok, {:person_registered, registered_person}}
    end)
  end
end
