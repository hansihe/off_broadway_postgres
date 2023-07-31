import Config

config :off_broadway_postgres, OffBroadwayPostgres.Test.Repo,
  migration_lock: false,
  name: OffBroadwayPostgres.Test.Repo,
  pool: Ecto.Adapters.SQL.Sandbox,
  priv: "test/support/postgres",
  url: System.get_env("DATABASE_URL") || "postgres://localhost:5432/off_broadway_postgres_test"

config :off_broadway_postgres,
  ecto_repos: [OffBroadwayPostgres.Test.Repo]
