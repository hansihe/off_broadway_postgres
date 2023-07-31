defmodule OffBroadwayPostgres.MigrationTest do
  use OffBroadwayPostgres.DataCase
  alias OffBroadwayPostgres.Migration

  import OffBroadwayPostgres.Migration, only: [initial_version: 0, current_version: 0]

  defmodule StepMigration do
    use Ecto.Migration

    def up do
      OffBroadwayPostgres.Migration.up(version: up_version(), prefix: "migrating")
    end

    def down do
      OffBroadwayPostgres.Migration.down(version: down_version(), prefix: "migrating")
    end

    defp up_version do
      Application.get_env(:off_broadway_postgres, :up_version)
    end

    def down_version do
      Application.get_env(:off_broadway_postgres, :down_version)
    end
  end

  defmodule DefaultMigration do
    use Ecto.Migration

    def up do
      OffBroadwayPostgres.Migration.up(prefix: "migrating")
    end

    def down do
      OffBroadwayPostgres.Migration.down(prefix: "migrating")
    end
  end

  @base_version 20_300_000_000_000

  test "migrating up and down between specific versions" do
    for up <- initial_version()..current_version() do
      Application.put_env(:off_broadway_postgres, :up_version, up)

      assert :ok = Ecto.Migrator.up(Repo, @base_version + up, StepMigration)
      assert migrated_version() == up
    end

    assert table_exists?("off_broadway_postgres_jobs")
    assert table_exists?("off_broadway_postgres_runners")
    assert migrated_version() == current_version()

    Application.put_env(:off_broadway_postgres, :down_version, 1)
    assert :ok = Ecto.Migrator.down(Repo, @base_version + 1, StepMigration)
  end

  test "migrating up and down between default versions" do
    assert :ok = Ecto.Migrator.up(Repo, @base_version, DefaultMigration)

    assert table_exists?("off_broadway_postgres_jobs")
    assert migrated_version() == current_version()

    # Migrating once more to replicate multiple migrations that don't specify a version.
    assert :ok = Ecto.Migrator.up(Repo, @base_version + 1, DefaultMigration)
    assert :ok = Ecto.Migrator.down(Repo, @base_version + 1, DefaultMigration)

    refute table_exists?("off_broadway_postgres_jobs")

    # Migrating once more to replicate multiple migrations that don't specify a version.
    assert :ok = Ecto.Migrator.down(Repo, @base_version, DefaultMigration)
  end

  def migrated_version do
    Migration.migrated_version(repo: Repo, prefix: "migrating")
  end

  defp table_exists?(table) do
    query = """
    SELECT EXISTS (
      SELECT 1
      FROM pg_tables
      WHERE schemaname = 'migrating'
      AND tablename = '#{table}'
    )
    """

    {:ok, %{rows: [[bool]]}} = Repo.query(query)

    bool
  end

end
