defmodule OffBroadwayPostgres.Ecto.Runner do
  use Ecto.Type

  @type t :: {pos_integer() | nil, pos_integer() | nil}

  def type, do: :off_broadway_postgres_runner

  def cast({runner_id, batch}) do
    {:ok, {runner_id, batch}}
  end

  def cast(_), do: :error

  def dump({runner_id, batch}) do
    {:ok, {runner_id, batch}}
  end

  def dump(_), do: :error

  def load({runner_id, batch}) do
    {:ok, {runner_id, batch}}
  end
end
