defmodule AuroraGov.Projector do
  use Commanded.Projections.Ecto,
    application: AuroraGov,
    repo: AuroraGov.Projector.Repo,
    name: "aurora_gov-projector-main",
    consistency: :strong

  require Logger

  alias AuroraGov.Event.VoteEmited
  alias AuroraGov.Projector.{MembershipProjector, PowerProjector, ProposalProjector}
  alias AuroraGov.Event.PowerUpdated
  alias AuroraGov.Event.MembershipPromoted
  alias AuroraGov.Event.{PersonRegistered, OUCreated, MembershipStarted, ProposalCreated}
  alias AuroraGov.Projector.Model.{Person, OU, Membership}

  project(
    %PersonRegistered{
      person_id: person_id,
      person_name: person_name,
      person_mail: person_mail,
      person_secret: person_secret
    },
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

  project(%MembershipStarted{} = evt, metadata, &MembershipProjector.project(evt, metadata, &1))

  project(%ProposalCreated{} = evt, metadata, &ProposalProjector.project(evt, metadata, &1))

  project(%VoteEmited{} = evt, metadata, &ProposalProjector.project(evt, metadata, &1))

  project(
    %MembershipPromoted{
      person_id: person_id,
      ou_id: ou_id,
      membership_status: membership_status
    },
    metadata,
    fn multi ->
      multi
      |> Ecto.Multi.run(:membership_lookup, fn repo, _changes ->
        case repo.get_by(Membership, person_id: person_id, ou_id: ou_id) do
          nil -> {:error, :membership_not_found}
          membership -> {:ok, membership}
        end
      end)
      |> Ecto.Multi.update(:membership_update, fn %{membership_lookup: membership} ->
        changeset =
          Ecto.Changeset.change(membership,
            membership_status: membership_status,
            updated_at: metadata.created_at
          )

        changeset
      end)
      |> Ecto.Multi.run(:membership_notification, fn repo, %{membership_update: membership} ->
        membership
        |> repo.preload([:ou, :person])
        |> then(&{:ok, &1})
      end)
    end
  )

  project(%PowerUpdated{} = evt, metadata, &PowerProjector.project(evt, metadata, &1))

  @impl Commanded.Projections.Ecto
  def after_update(_event, _metadata, %{projector_update: projector_update}) do
    Logger.debug("Notificando (projector_update) #{inspect(projector_update)}")
    Phoenix.PubSub.broadcast(AuroraGov.PubSub, "projector_update", {:projector_update, projector_update})
    :ok
  end

  @impl Commanded.Projections.Ecto
  def after_update(_event, _metadata, data) do
    Logger.debug("Notificando (projector_update) (Sin datos para notificar) #{inspect(data)}")
    :ok
  end

  @impl true
  def error({:error, error}, event, _failure_context) do
    Logger.error("Error al proyectar #{inspect(error)} #{inspect(event)}")
    :skip
  end
end
