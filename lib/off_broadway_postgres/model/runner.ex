defmodule OffBroadwayPostgres.Model.Runner do
  use Ecto.Schema

  schema "off_broadway_postgres_runners" do
    field :heartbeat, :utc_datetime
  end

  def active_runners_query do
    import Ecto.Query

    from(
      r in OffBroadwayPostgres.Model.Runner,
      where: r.heartbeat > fragment("now() - interval '60 second'")
    )
  end
end
