defmodule OffBroadwayPostgres do
  @moduledoc """
  Documentation for `OffBroadwayPostgres`.
  """

  def pg_name(name) do
    {__MODULE__, name}
  end

  def notify_poll_pg(pg_scope \\ :pg, name) do
    group_name = pg_name(name)

    members = :pg.get_members(pg_scope, group_name)
    for pid <- members do
      send(pid, :poll)
    end

    if Enum.empty?(members) do
      :error
    else
      :ok
    end
  end
end
