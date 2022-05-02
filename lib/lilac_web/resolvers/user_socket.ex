defmodule LilacWeb.UserSocket do
  use Phoenix.Socket
  use Absinthe.Phoenix.Socket, schema: LilacWeb.Schema

  def connect(_params, socket) do
    {:ok, socket}
  end

  def id(_socket), do: nil
end
