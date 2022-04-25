defmodule Lilac.Services.LastFMAPI do
  use HTTPoison.Base

  def process_request_url(nil) do
    "http://ws.audioscrobbler.com/2.0/?format=json&api_key=43674eff779de85186195dd069b770dd"
  end

  def process_request_url(parameters) do
    process_request_url(nil) <> "&" <> parameters
  end

  def process_response_body(body) do
    case Poison.decode(body) do
      {:ok, decoded} -> decoded
      {:error, _error} -> IO.puts(inspect(body))
    end
  end
end
