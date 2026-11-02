defmodule AuroraGov.Projector.OUProjector do
  import Ecto.Query

  alias AuroraGov.Event.{
    OUCreated,
    OURenamed,
    OUGoalUpdated,
    OUAvatarUpdated
  }

  alias AuroraGov.Projector.Model.OU

  def project(
        %OUCreated{
          ou_id: ou_id,
          ou_name: ou_name,
          ou_goal: ou_goal,
          ou_description: ou_description
        },
        metadata,
        multi
      ) do
    projection = %OU{
      ou_id: ou_id,
      ou_name: ou_name,
      ou_goal: ou_goal,
      ou_description: ou_description,
      ou_status: :active,
      created_at: metadata.created_at,
      updated_at: metadata.created_at
    }

    multi
    |> Ecto.Multi.insert(:ou_table, projection)
    |> Ecto.Multi.run(:projector_update, fn _repo, %{ou_table: created_ou} ->
      {:ok, {:ou_created, created_ou}}
    end)
  end

  def project(
        %OURenamed{
          ou_id: ou_id,
          ou_name: ou_name
        },
        metadata,
        multi
      ) do
    query =
      from(ou in OU,
        where: ou.ou_id == ^ou_id,
        update: [
          set: [
            ou_name: ^ou_name,
            updated_at: ^metadata.created_at
          ]
        ],
        select: ou
      )

    multi
    |> Ecto.Multi.update_all(:ou_rename_update, query, [])
    |> Ecto.Multi.run(
      :projector_update,
      fn _repo, %{ou_rename_update: {1, [updated_ou]}} ->
        {:ok, {:ou_renamed, updated_ou}}
      end
    )
  end

  @doc """
  Proyecta el evento OUGoalUpdated sobre el read model
  de la unidad organizacional.

  Actualiza el objetivo de la OU.
  """
  def project(
        %OUGoalUpdated{
          ou_id: ou_id,
          ou_goal: ou_goal
        },
        metadata,
        multi
      ) do
    query =
      from(ou in OU,
        where: ou.ou_id == ^ou_id,
        update: [
          set: [
            ou_goal: ^ou_goal,
            updated_at: ^metadata.created_at
          ]
        ],
        select: ou
      )

    multi
    |> Ecto.Multi.update_all(:ou_goal_update, query, [])
    |> Ecto.Multi.run(
      :projector_update,
      fn _repo, %{ou_goal_update: {1, [updated_ou]}} ->
        {:ok, {:ou_goal_updated, updated_ou}}
      end
    )
  end

  def project(
        %OUAvatarUpdated{
          ou_id: ou_id,
          ou_avatar_url: ou_avatar_url,
          file_hash: file_hash
        },
        metadata,
        multi
      ) do
    query =
      from(ou in OU,
        where: ou.ou_id == ^ou_id,
        update: [
          set: [
            ou_avatar_url: ^ou_avatar_url,
            ou_avatar_hash: ^file_hash,
            updated_at: ^metadata.created_at
          ]
        ],
        select: ou
      )

    multi
    |> Ecto.Multi.update_all(:ou_avatar_update, query, [])
    |> Ecto.Multi.run(
      :projector_update,
      fn _repo, %{ou_avatar_update: {1, [updated_ou]}} ->
        {:ok, {:ou_avatar_updated, updated_ou}}
      end
    )
  end
end
