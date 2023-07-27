ExUnit.start()

Application.put_env(
  :ecto,
  TestRepo,
  adapter: Ecto.Adapters.Postgres,
  url: System.get_env("DATABASE_URL", "postgresql://postgres:postgres@localhost:5432/off_broadway_postgres_test"),
  pool: Ecto.Adapters.SQL.Sandbox
)

defmodule TestRepo do
  use Ecto.Repo,
    otp_app: :ecto,
    adapter: Ecto.Adapters.Postgres
end

{:ok, _} = Ecto.Adapters.Postgres.ensure_all_started(TestRepo, :temporary)

_ = Ecto.Adapters.Postgres.storage_down(TestRepo.config())
:ok = Ecto.Adapters.Postgres.storage_up(TestRepo.config())

{:ok, _pid} = TestRepo.start_link()

Code.require_file("ecto_migration.exs", __DIR__)
OffBroadwayPostgres.Migration.up(version: 2)
