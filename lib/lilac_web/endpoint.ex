defmodule LilacWeb.Endpoint do
  use Plug.ErrorHandler
  use Phoenix.Endpoint, otp_app: :lilac
  use Absinthe.Phoenix.Endpoint

  plug CORSPlug, origin: ["*"]

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  @session_options [
    store: :cookie,
    key: "_lilac_key",
    signing_salt: "EOn+E+nw",
    same_site: "Lax"
  ]

  socket "/socket", LilacWeb.UserSocket, websocket: true

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phx.digest
  # when deploying your static files in production.
  plug Plug.Static,
    at: "/",
    from: :lilac,
    gzip: false,
    only: LilacWeb.static_paths()

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    plug Phoenix.CodeReloader
    plug Phoenix.Ecto.CheckRepoStatus, otp_app: :lilac
  end

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options

  plug Absinthe.Plug.GraphiQL, schema: LilacWeb.Schema, socket: LilacWeb.UserSocket

  plug LilacWeb.Plugs.Auth
  plug LilacWeb.Plugs.Context

  @impl Plug.ErrorHandler
  def handle_errors(conn, error) do
    send_resp(
      conn,
      conn.status,
      error
      |> Map.put(:user, %{})
      |> LilacWeb.ErrorReporter.handle_error()
      |> Jason.encode!()
    )
  end
end
