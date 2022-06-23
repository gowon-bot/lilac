defmodule LilacWeb.Plugs.Context do
  @behaviour Plug

  def init(opts), do: opts

  @spec call(Plug.Conn.t(), any) :: Plug.Conn.t()
  def call(conn, _) do
    context = build_context(conn)
    Absinthe.Plug.put_options(conn, context: context)
  end

  def build_context(conn) do
    doughnut_id =
      Enum.find(conn.req_headers, fn header -> elem(header, 0) == "doughnut-discord-id" end)

    %{
      doughnut_id: if(is_nil(doughnut_id), do: nil, else: elem(doughnut_id, 1))
    }
  end
end
