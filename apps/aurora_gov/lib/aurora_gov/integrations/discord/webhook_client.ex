defmodule AuroraGov.Integrations.Discord.WebhookClient do
  @moduledoc """
  Envía embeds al webhook de Discord configurado en la aplicación.

  No conoce eventos ni reglas del dominio.
  Devuelve el resultado del envío para que el llamador decida
  cómo manejar los errores y los posibles reintentos.
  """

  @headers [{"content-type", "application/json"}]

  @doc """
  Envía un único embed.

  Resultados:
    * {:ok, message_id}
    * {:ok, :disabled}
    * {:error, reason}
  """
  @spec send_embed(map()) ::
          {:ok, String.t() | :disabled} | {:error, term()}
  def send_embed(embed) when is_map(embed) do
    config = Application.get_env(:aurora_gov, :discord_notifications, [])

    if Keyword.get(config, :enabled, false) do
      with {:ok, url} <- webhook_url(config),
           {:ok, body} <- encode_payload(embed) do
        deliver(url, body)
      end
    else
      {:ok, :disabled}
    end
  end

  # Validamos el destino sin incluir el token en los errores.
  defp webhook_url(config) do
    case Keyword.get(config, :webhook_url) do
      url when is_binary(url) ->
        uri = URI.parse(String.trim(url))

        valid_path? =
          Regex.match?(
            ~r{^/api(?:/v[0-9]+)?/webhooks/[0-9]+/[A-Za-z0-9._-]+$},
            uri.path || ""
          )

        if uri.scheme == "https" and
             uri.host == "discord.com" and
             uri.port == 443 and
             is_nil(uri.userinfo) and
             is_nil(uri.fragment) and
             valid_path? do
          # Conservamos los parámetros existentes y pedimos confirmación.
          query =
            (uri.query || "")
            |> URI.decode_query()
            |> Map.put("wait", "true")
            |> URI.encode_query()

          {:ok, URI.to_string(%{uri | query: query})}
        else
          {:error, :invalid_webhook_url}
        end

      _ ->
        {:error, :missing_webhook_url}
    end
  end

  defp encode_payload(embed) do
    payload = %{
      username: "AuroraGov",
      embeds: [embed],
      allowed_mentions: %{parse: []}
    }

    case Jason.encode(payload) do
      {:ok, body} -> {:ok, body}
      {:error, _reason} -> {:error, :invalid_payload}
    end
  end

  defp deliver(url, body) do
    request = Finch.build(:post, url, @headers, body)

    case Finch.request(
           request,
           AuroraGov.Finch,
           receive_timeout: 10_000,
           pool_timeout: 5_000
         ) do
      {:ok, response} ->
        handle_response(response)

      {:error, _reason} ->
        # No exponemos información de la petición ni el token.
        {:error, :transport_error}
    end
  end

  defp handle_response(%Finch.Response{status: 200, body: body}) do
    case Jason.decode(body) do
      {:ok, %{"id" => message_id}} when is_binary(message_id) ->
        {:ok, message_id}

      _ ->
        {:error, :unexpected_response}
    end
  end

  defp handle_response(%Finch.Response{status: 429, body: body}) do
    # Discord expresa retry_after en segundos.
    retry_after =
      case Jason.decode(body) do
        {:ok, %{"retry_after" => seconds}}
        when is_number(seconds) and seconds >= 0 ->
          seconds

        _ ->
          nil
      end

    {:error, {:rate_limited, retry_after}}
  end

  defp handle_response(%Finch.Response{status: status})
       when status >= 500 do
    {:error, {:server_error, status}}
  end

  defp handle_response(%Finch.Response{status: status}) do
    {:error, {:http_error, status}}
  end
end
