defmodule OffBroadwayPostgres.ProducerTest do
  use OffBroadwayPostgres.DataCase

  alias OffBroadwayPostgres.Test
  alias OffBroadwayPostgres.Producer
  alias OffBroadwayPostgres.Test.{Source, Model}

  test "job claim" do
    source = {Source, []}
    state = Test.init(source)

    {:ok, runner, state} = Test.make_runner(state)
    assert {:ok, []} = Producer.claim_jobs(source, runner, 5)

    Repo.insert_all(Model.Item, Enum.map(0..7, fn _ -> %{done: false} end))

    {:ok, runner, state} = Test.make_runner(state)
    assert {:ok, [_, _, _, _, _]} = Producer.claim_jobs(source, runner, 5)

    {:ok, runner, state} = Test.make_runner(state)
    assert {:ok, [_, _, _]} = Producer.claim_jobs(source, runner, 5)

    {:ok, runner, state} = Test.make_runner(state)
    assert {:ok, []} = Producer.claim_jobs(source, runner, 5)
  end
end
