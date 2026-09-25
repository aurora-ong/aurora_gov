defmodule AuroraGov.Integrations.Discord.ProposalEmbed do
  @moduledoc """
  Construye embeds para notificaciones de propuestas.

  No consulta repositorios ni realiza peticiones HTTP.

  Las opciones permiten recibir nombres previamente resueltos:
    * :owner_name
    * :origin_name
    * :destination_name
    * :power_name
    * :occurred_at — DateTime del evento
  """

  alias AuroraGov.Event.{ProposalCreated, ProposalConsumed}

  @doc """
  Construye el embed de una propuesta recién creada.
  """
  def created(%ProposalCreated{} = event, opts \\ []) do
    build(
      event,
      "Nueva propuesta",
      "Abierta a votación",
      0x3498DB,
      opts
    )
  end

  @doc """
  Construye el embed del resultado de ejecución.

  `proposal` debe contener los datos de la propuesta correspondiente:
  puede ser el evento ProposalCreated o el modelo de lectura.

  El resultado se toma del evento ProposalConsumed, no del modelo
  de lectura, que podría no haberse actualizado todavía.
  """
  def consumed(event, proposal, opts \\ [])

  def consumed(
        %ProposalConsumed{proposal_id: id} = event,
        %{proposal_id: id} = proposal,
        opts
      )
      when is_binary(id) do
    {heading, status, color} =
      execution_style(event.proposal_execution_result)

    build(proposal, heading, status, color, opts)
  end

  def consumed(%ProposalConsumed{}, _proposal, _opts) do
    raise ArgumentError,
          "el evento y los datos deben corresponder a la misma propuesta"
  end

  defp execution_style(result) when result in [:success, "success"] do
    {"Propuesta ejecutada", "Ejecución exitosa", 0x2ECC71}
  end

  defp execution_style(result) when result in [:failed, "failed"] do
    {"Ejecución fallida", "La ejecución registró un error", 0xE74C3C}
  end

  defp execution_style(_result) do
    {"Resultado no reconocido", "Requiere revisión", 0xF1C40F}
  end

  defp build(proposal, heading, status, color, opts) do
    embed = %{
      title: heading,
      description:
        text(
          Map.get(proposal, :proposal_description),
          "Sin descripción.",
          2_000
        ),
      color: color,
      fields: [
        field(
          "Propuesta",
          Map.get(proposal, :proposal_title),
          "Sin título",
          false
        ),
        field("Estado", status, "Sin estado", false),
        field(
          "Acción",
          named_value(opts, :power_name, proposal, :proposal_power_id),
          "Acción no disponible",
          false
        ),
        field(
          "Proponente",
          named_value(opts, :owner_name, proposal, :proposal_owner_id),
          "Proponente no disponible",
          true
        ),
        field(
          "Unidad de origen",
          named_value(opts, :origin_name, proposal, :proposal_ou_start_id),
          "Unidad no disponible",
          true
        ),
        field(
          "Unidad de destino",
          named_value(opts, :destination_name, proposal, :proposal_ou_end_id),
          "Unidad no disponible",
          true
        ),
        field(
          "ID de propuesta",
          Map.get(proposal, :proposal_id),
          "ID no disponible",
          false
        )
      ],
      footer: %{text: "AuroraGov · Gobernanza"}
    }

    put_timestamp(embed, Keyword.get(opts, :occurred_at))
  end

  # Preferimos un nombre legible; si falta, mostramos el identificador.
  defp named_value(opts, option, proposal, id_key) do
    case Keyword.get(opts, option) do
      value when is_binary(value) ->
        if String.trim(value) == "" do
          Map.get(proposal, id_key)
        else
          value
        end

      _ ->
        Map.get(proposal, id_key)
    end
  end

  defp field(name, value, fallback, inline) do
    %{
      name: name,
      value: text(value, fallback, 400),
      inline: inline
    }
  end

  defp text(value, fallback, limit) do
    value =
      case value do
        value when is_binary(value) ->
          case String.trim(value) do
            "" -> fallback
            trimmed -> trimmed
          end

        _ ->
          fallback
      end

    truncate(value, limit)
  end

  # Medimos unidades UTF-16 para reservar espacio también para emojis.
  # El recorrido conserva los caracteres Unicode completos.
  defp truncate(value, limit) do
    if units(value) <= limit do
      value
    else
      {reversed, _remaining} =
        value
        |> String.codepoints()
        |> Enum.reduce_while({[], limit - 1}, fn character, {acc, remaining} ->
          size = units(character)

          if size <= remaining do
            {:cont, {[character | acc], remaining - size}}
          else
            {:halt, {acc, remaining}}
          end
        end)

      (reversed |> Enum.reverse() |> Enum.join()) <> "…"
    end
  end

  defp units(value) do
    value
    |> :unicode.characters_to_binary(:utf8, {:utf16, :little})
    |> byte_size()
    |> div(2)
  end

  defp put_timestamp(embed, %DateTime{} = occurred_at) do
    Map.put(embed, :timestamp, DateTime.to_iso8601(occurred_at))
  end

  defp put_timestamp(embed, _), do: embed
end
