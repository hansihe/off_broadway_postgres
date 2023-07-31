defmodule OffBroadwayPostgres.Producer.SchedulerTest do
  use ExUnit.Case
  alias OffBroadwayPostgres.Producer.Scheduler

  test "foo" do
    assert {state, false, 10_000} = Scheduler.new()
    assert {state, true, 10_000} = Scheduler.on_demand(state, 10)
  end

end
