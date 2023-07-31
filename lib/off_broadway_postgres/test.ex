defmodule OffBroadwayPostgres.Test do
  defstruct [
    runner_id: nil,
    source: nil,
    repo: nil,
    batch_idx: 1
  ]

  alias OffBroadwayPostgres.Producer

  def init({source_module, source_arg} = source) do
    repo = source_module.repo(source_arg)
    %__MODULE__{
      source: source,
      repo: repo,
      runner_id: Producer.insert_runner(repo)
    }
  end

  def make_runner(state) do
    batch_idx = state.batch_idx
    state = %{state | batch_idx: batch_idx + 1}
    {:ok, {state.runner_id, batch_idx}, state}
  end

  def claim_jobs(state, num) do
    {:ok, runner, state} = make_runner(state)
    {:ok, jobs} = Producer.claim_jobs(state.source, runner, num)
    {:ok, state, jobs}
  end

  def simulate_pipeline(state, pipeline, num_jobs) when is_integer(num_jobs) do
    {:ok, state, jobs} = claim_jobs(state, num_jobs)
    simulate_pipeline(state, pipeline, jobs)
  end

  def simulate_pipeline(state, pipeline, jobs) do
    map_results =
      jobs
      |> Enum.map(&%Broadway.Message{data: &1, acknowledger: nil})
      |> Enum.map(&pipeline.handle_message(:default, &1, nil))
      |> Enum.group_by(& &1.status == :ok)

    map_success = map_results[true] || []
    map_failed = map_results[false] || []

    reduce_results =
      pipeline.handle_batch(:default, map_success, nil, nil)
      |> Enum.group_by(& &1.status == :ok)

    reduce_success = reduce_results[true] || []
    reduce_failed = reduce_results[false] || []

    success = reduce_success
    failed = map_failed ++ reduce_failed

    :ok = Producer.finish_jobs(state.source, :test_pipeline, success, failed)

    {:ok, state}
  end

end
