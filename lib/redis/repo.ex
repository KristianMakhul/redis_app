defmodule Redis.Repo do
  use Ecto.Repo,
    otp_app: :redis,
    adapter: Ecto.Adapters.Postgres
end
