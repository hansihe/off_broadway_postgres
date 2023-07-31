defmodule OffBroadwayPostgres.Test.Repo do
  use Ecto.Repo,
    otp_app: :off_broadway_postgres,
    adapter: Ecto.Adapters.Postgres
end
