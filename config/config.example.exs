import Config

# Database config
config :lilac, Lilac.Repo,
  username: "postgres username here",
  password: "postgres password here",
  hostname: "localhost",
  database: "lilac",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10,
  log: false

# Last.fm config
config :lilac,
  last_fm_api_key: "get me from https://last.fm/api",
  last_fm_api_secret: "^",

# General config
config :lilac,
  password: "this needs to match the password set in Gowon"

# Redis config
config :lilac,
  redis_host: "<your redis host>"
