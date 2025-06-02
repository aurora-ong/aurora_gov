defmodule AuroraGov.Projector do
  use Commanded.Projections.Ecto,
    application: AuroraGov,
    repo: AuroraGov.Projector.Repo,
    name: "aurora_gov-projector-main",
    consistency: :strong

  require Logger

  alias AuroraGov.Event.{PersonRegistered, OUCreated, MembershipStarted}
  alias AuroraGov.Projector.Model.{Person, OU, Membership}

  project(
    %PersonRegistered{person_id: person_id, person_name: person_name, person_mail: person_mail, person_secret: person_secret},
    metadata,
    fn multi ->
      projection = %Person{
        person_id: person_id,
        person_name: person_name,
        person_mail: person_mail,
        person_secret: person_secret,
        created_at: metadata.created_at,
        updated_at: metadata.created_at
      }

      Ecto.Multi.insert(multi, :person_table, projection)
    end
  )

  project(
    %OUCreated{ou_id: ou_id, ou_name: ou_name, ou_goal: ou_goal, ou_description: ou_description},
    metadata,
    fn multi ->
      projection = %OU{
        ou_id: ou_id,
        ou_name: ou_name,
        ou_goal: ou_goal,
        ou_description: ou_description,
        ou_status: :active,
        created_at: metadata.created_at,
        updated_at: metadata.created_at
      }

      Ecto.Multi.insert(multi, :ou_table, projection)
    end
  )

  project(
    %MembershipStarted{membership_id: membership_id, ou_id: ou_id, person_id: person_id},
    metadata,
    fn multi ->
      projection = %Membership{
        membership_id: membership_id,
        ou_id: ou_id,
        person_id: person_id,
        membership_status: :junior,
        created_at: metadata.created_at,
        updated_at: metadata.created_at
      }

      multi
      |> Ecto.Multi.insert(:membership_table_insert, projection,
        returning: true,
        preload: [:ou]
      )
      |> Ecto.Multi.run(:membership_notification, fn repo,
                                                     %{membership_table_insert: membership} ->
        # Realizamos una consulta para precargar las asociaciones
        membership
        |> repo.preload([:ou, :person])
        |> then(&{:ok, &1})
      end)
    end
  )

  @impl Commanded.Projections.Ecto
  def after_update(event, metadata, changes) do
    IO.inspect(event, label: "Notificando (event)")
    IO.inspect(changes, label: "Notificando (changes)")
    IO.inspect(metadata, label: "Notificando (metadata)")
    Phoenix.PubSub.broadcast(AuroraGov.PubSub, "projector_update", changes)
    :ok
  end

  @impl true
  def error({:error, error}, event, _failure_context) do
    Logger.error("Error al proyectar #{inspect(error)} #{inspect(event)}")
    :skip
  end
end
