defmodule OffBroadwayPostgres.Migration do
  use Ecto.Migration

  def up(version: 2) do
    create table("off_broadway_postgres_runners") do
      add(:heartbeat, :utc_datetime)
    end

    create table("off_broadway_postgres_jobs") do
      add(:status, :string, null: false)
      add(:attempt, :integer, null: false, default: 0)
      add(:errors, {:array, :text})
      add(:pipeline_name, :text, null: false)
    end

    execute("""
    CREATE TYPE off_broadway_postgres_runner AS (
      runner_id bigint,
      batch bigint
    );
    """)
  end

  def down(version: 1) do
    drop(table("off_broadway_postgres_jobs"))
    drop(table("off_broadway_postgres_runners"))

    execute("""
    DROP TYPE off_broadway_postgres_runner;
    """)
  end
end
