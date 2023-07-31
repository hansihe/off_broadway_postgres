Application.ensure_all_started(:postgrex)
OffBroadwayPostgres.Test.Repo.start_link()

ExUnit.start()

Ecto.Adapters.SQL.Sandbox.mode(OffBroadwayPostgres.Test.Repo, :manual)
