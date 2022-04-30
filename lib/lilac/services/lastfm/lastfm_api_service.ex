defmodule Lilac.LastFM.API do
  use HTTPoison.Base

  alias Lilac.LastFM.{Responses, Errors}

  def process_request_url(nil) do
    "http://ws.audioscrobbler.com/2.0/"
  end

  def process_request_url(parameters) do
    process_request_url(nil) <> "?" <> parameters
  end

  def process_response_body(body) do
    case Poison.decode(body) do
      {:ok, decoded} -> decoded
      {:error, _error} -> IO.puts(inspect(body))
    end
  end

  @spec handle_response(term) :: {:ok | :error, struct}
  def handle_response(response) do
    case response do
      {:error, error} ->
        %Errors.ConnectionError{
          status_code: if(Map.has_key?(error, :status_code), do: error.status_code, else: nil),
          reason: if(Map.has_key?(error, :reason), do: error.reason, else: nil)
        }

      {:ok, %{body: body}} ->
        if Map.has_key?(body, "error"),
          do: {:error, Errors.parse_error(body)},
          else: {:ok, Responses.RecentTracks.from_map(body)}
    end
  end
end
