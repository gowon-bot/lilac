defmodule LilacWeb.Plugs.Auth do
  import Plug.Conn

  def init(default), do: default

  @spec call(Plug.Conn.t(), any) :: Plug.Conn.t()
  def call(conn, _default) do
    authorization =
      Enum.find(conn.req_headers, fn header -> elem(header, 0) == "authorization" end)

    if is_nil(authorization) ||
         elem(authorization, 1) !== Application.fetch_env!(:lilac, :password) do
      conn
      |> send_resp(
        401,
        Jason.encode!(%{status: 401, message: "You are not authorized to make this request!"})
      )
      |> halt
    else
      conn
    end
  end
end
