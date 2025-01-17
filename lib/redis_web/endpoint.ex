defmodule RedisWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :redis

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  @session_options [
    store: :cookie,
    key: "_redis_key",
    signing_salt: "uMmLiMP6",
    same_site: "Lax"
  ]

  plug(Plug.Static,
    at: "/moon/assets",
    from: :moon,
    gzip: true,
    only: ~w(assets themes images fonts svgs favicon.ico robots.txt),
    cache_control_for_etags: "public, max-age=86400"
  )

  plug(Plug.Static,
    at: "/moon_icons/",
    from: :moon_icons,
    gzip: true,
    cache_control_for_etags: "public, max-age=86400"
  )

  socket "/live", Phoenix.LiveView.Socket,
    websocket: [connect_info: [session: @session_options]],
    longpoll: [connect_info: [session: @session_options]]

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phx.digest
  # when deploying your static files in production.
  plug Plug.Static,
    at: "/",
    from: :redis,
    gzip: false,
    only: RedisWeb.static_paths()

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
    plug Phoenix.Ecto.CheckRepoStatus, otp_app: :redis
  end

  plug Phoenix.LiveDashboard.RequestLogger,
    param_key: "request_logger",
    cookie_key: "request_logger"

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options
  plug RedisWeb.Router
end
