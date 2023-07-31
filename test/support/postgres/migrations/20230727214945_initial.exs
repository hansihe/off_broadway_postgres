defmodule OffBroadwayPostgres.Test.Repo.Migrations.Initial do
  use Ecto.Migration

  def up do
    OffBroadwayPostgres.Migration.up([])

    create table("items") do
      add :done, :boolean
      add :job_id, :int8
      add :job_runner, :off_broadway_postgres_runner
    end
  end
end
