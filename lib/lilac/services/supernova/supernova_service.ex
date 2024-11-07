defmodule Lilac.Supernova do
  alias Lilac.Supernova.API
  alias Lilac.Supernova.Types

  @spec report(Types.Payload.t()) :: {:ok, Types.ErrorResponse} | {:error, struct}
  def report(payload) do
    API.post("errors/report", payload)
  end
end
