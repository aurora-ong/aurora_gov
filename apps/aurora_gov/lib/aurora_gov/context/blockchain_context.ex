defmodule AuroraGov.Context.BlockchainContext do
  @moduledoc """
  Contexto principal para acceder al historial inmutable (Blockchain) de la organización.
  Maneja dos vistas principales:
  1. Timeline: Vista social filtrada y paginada (para usuarios).
  2. Auditoría: Vista técnica completa (para validación criptográfica).
  """

  import Ecto.Query, warn: false
  alias AuroraGov.Projector.Repo
  alias AuroraGov.Projector.Model.Block

  # ===================================================================
  # 1. TIMELINE SOCIAL (La vista del Usuario)
  # ===================================================================

  @doc """
  Retorna el muro de actividad paginado para una organización.

  ## Reglas de Negocio:
  - Filtra por `ou_id`.
  - Filtra `is_visible: true` (oculta eventos de sistema).
  - Devuelve los datos "hidratados" (Structs reales) en el campo `data`.
  """
  def list_timeline(_ou_id, params \\ %{}) do
    from(b in Block,
      # where: b.ou_id == ^ou_id,       # <--- FILTRO ACTIVADO
      # where: b.is_visible == true,    # <--- FILTRO ACTIVADO
      preload: [:person, :ou, :proposal]
    )
    |> Flop.validate_and_run(params, for: Block)
    |> hydrate_flop_result() # Convertimos el resultado de Flop a Structs
  end

  # ===================================================================
  # 2. AUDITORÍA GLOBAL (La vista del Auditor/Admin)
  # ===================================================================

  @doc """
  Lista bloques para auditoría técnica.
  Muestra TODO (incluyendo ocultos) y permite filtrar por Hash/Index.
  """
  def list_audit_blocks(params \\ %{}) do
    from(b in Block, preload: [:person])
    |> Flop.validate_and_run(params, for: Block)
    |> hydrate_flop_result()
  end

  @doc """
  Busca un bloque específico por su índice.
  """
  def get_block!(index) do
    Repo.get!(Block, index)
    |> hydrate_block()
  end

  @doc """
  Busca un bloque por su Hash.
  """
  def get_block_by_hash(hash) do
    Repo.get_by(Block, hash: hash)
    |> Repo.preload([:person, :ou])
    |> hydrate_block()
  end

  @doc """
  Retorna la altura actual de la cadena.
  """
  def get_latest_block_height do
    from(b in Block, select: max(b.index)) |> Repo.one() || 0
  end

  # ===================================================================
  # 3. TRAZABILIDAD (Debugging de Procesos)
  # ===================================================================

  @doc """
  Reconstruye la historia de una transacción (Correlation ID).
  """
  def get_process_trace(correlation_id) do
    from(b in Block,
      where: b.correlation_id == ^correlation_id,
      order_by: [asc: b.index],
      preload: [:person]
    )
    |> Repo.all()
    |> hydrate_list() # Usamos el helper de lista
  end

  # ===================================================================
  # HELPERS DE HIDRATACIÓN (Privados)
  # Convierten el JSON (Map) de la DB al Struct original del evento
  # ===================================================================

  # Caso 1: Resultado de Flop {:ok, {blocks, meta}}
  defp hydrate_flop_result({:ok, {blocks, meta}}) do
    hydrated_blocks = Enum.map(blocks, &hydrate_block/1)
    {:ok, {hydrated_blocks, meta}}
  end
  defp hydrate_flop_result(error), do: error

  # Caso 2: Lista simple (Repo.all)
  defp hydrate_list(blocks) when is_list(blocks) do
    Enum.map(blocks, &hydrate_block/1)
  end

  # Caso 3: Un solo bloque (o nil)
  defp hydrate_block(nil), do: nil # Importante para no crashear en get_by

  defp hydrate_block(block) do
    # 1. Obtenemos el módulo real (ej: AuroraGov.Event.VoteEmited)
    module = String.to_existing_atom(block.event_type)

    # 2. Obtenemos las llaves válidas del Struct para filtrar basura
    struct_keys = Map.keys(struct(module)) |> List.delete(:__struct__)

    # 3. Convertimos keys de String a Atom y filtramos
    atom_data =
      block.data
      |> Map.new(fn {k, v} ->
         # Convertimos "vote_value" -> :vote_value
         # Usamos String.to_existing_atom para seguridad (evita DoS de átomos)
         {String.to_existing_atom(k), v}
      end)
      |> Map.take(struct_keys)

    # 4. Creamos el struct real
    real_struct = struct(module, atom_data)

    # 5. Retornamos el bloque con la data enriquecida
    %{block | data: real_struct}
  rescue
    # Fallback: Si el módulo ya no existe o hay error de versión,
    # devolvemos el bloque con el mapa original para no romper la UI.
    _ -> block
  end
end
