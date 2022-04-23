defmodule Lilac.Repo do
  use Ecto.Repo,
    otp_app: :lilac,
    adapter: Ecto.Adapters.Postgres
end
