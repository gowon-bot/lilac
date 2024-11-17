defmodule Lilac.Supernova.API do
  use HTTPoison.Base

  def process_request_url(path) do
    Application.fetch_env!(:lilac, :supernova_url) <> path
  end

  def process_request_headers(headers) do
    headers ++
      [
        {"Authentication", "Password #{Application.fetch_env!(:lilac, :supernova_password)}"},
        {"Content-Type", "application/json"}
      ]
  end

  def process_request_body(body) do
    body |> Map.from_struct() |> Jason.encode!()
  end

  def process_response_body(body) do
    case Poison.decode(body) do
      {:ok, decoded} -> decoded
      {:error, error} -> raise error
    end
  end
end
