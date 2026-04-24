defmodule AuroraGov.Blockchain.Projector do
  use Commanded.Projections.Ecto,
    application: AuroraGov,
    repo: AuroraGov.Projector.Repo,
    name: "aurora_gov-projector-blockchain",
    consistency: :strong

  require Logger
  alias AuroraGov.Projector.Repo
  alias AuroraGov.Blockchain.Hasher
  alias AuroraGov.Projector.Model.Block

  project(%_struct{} = event, metadata, fn multi ->
    last_entry = Repo.one(from c in Block, order_by: [desc: c.index], limit: 1)
    {prev_hash, new_index} = get_chain_link(last_entry)
    Logger.info("Proyectando nuevo hash")

    payload_hash = Hasher.hash_event(event)
    current_hash = :crypto.hash(:sha256, payload_hash <> prev_hash) |> Base.encode16()

    # is_visible = event.__struct__ in @timeline_events

    entry = %Block{
      index: new_index,
      hash: current_hash,
      prev_hash: prev_hash,
      event_id: metadata.event_id,
      # is_visible: is_visible,
      ou_id: extract_ou_id(event),
      person_id: extract_person_id(event),
      event_type: Atom.to_string(event.__struct__),
      data: Map.from_struct(event),
      correlation_id: metadata.correlation_id,
      causation_id: metadata.causation_id,
      occurred_at: metadata.created_at
    }

    Ecto.Multi.insert(multi, :chain_insert, entry)
  end)

  @genesis_hash String.duplicate("0", 64)

  defp get_chain_link(nil), do: {@genesis_hash, 1}
  defp get_chain_link(entry), do: {entry.hash, entry.index + 1}

  defp extract_ou_id(%{proposal_ou_end_id: id}) when is_binary(id), do: id
  defp extract_ou_id(%{ou_id: id}) when is_binary(id), do: id

  defp extract_ou_id(event) do
    Logger.warning("Blockchain: No se pudo obtener ou_id de evento: #{inspect(event)}")

    ""
  end

  defp extract_person_id(%{person_id: id}), do: id

  defp extract_person_id(event) do
    Logger.warning("Blockchain: No se pudo obtener person_id de evento: #{inspect(event)}")
    ""
  end
end
