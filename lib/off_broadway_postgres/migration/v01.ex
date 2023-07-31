defmodule OffBroadwayPostgres.Migration.V01 do
  use Ecto.Migration

  def up(%{create_schema: create?, prefix: prefix} = opts) do
    %{quoted_prefix: quoted} = opts

    if create?, do: execute("CREATE SCHEMA IF NOT EXISTS #{quoted}")

    create table("off_broadway_postgres_runners", prefix: prefix) do
      add(:heartbeat, :utc_datetime)
    end

    create table("off_broadway_postgres_jobs", prefix: prefix) do
      add(:status, :string, null: false)
      add(:attempt, :integer, null: false, default: 0)
      add(:errors, {:array, :text})
      add(:pipeline_name, :text, null: false)
    end

    execute("""
    CREATE TYPE #{quoted}.off_broadway_postgres_runner AS (
      runner_id bigint,
      batch bigint
    );
    """)
  end

  def down(%{prefix: prefix, quoted_prefix: quoted}) do
    drop_if_exists(table("off_broadway_postgres_jobs", prefix: prefix))
    drop_if_exists(table("off_broadway_postgres_runners", prefix: prefix))

    execute("""
    DROP TYPE IF EXISTS #{quoted}.off_broadway_postgres_runner;
    """)
  end
end
