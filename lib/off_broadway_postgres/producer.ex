defmodule OffBroadwayPostgres.Producer do
  # :erlang.monotonic_time(:millisecond)

  @moduledoc """

  ## Options
  #{NimbleOptions.docs(OffBroadwayPostgres.Options.definition())}

  """

  use GenStage
  @behaviour Broadway.Producer

  require Logger
  alias OffBroadwayPostgres.Options

  @impl GenStage
  def init(opts) do
    {source_mod, source_arg} = opts[:source]
    repo = source_mod.repo(source_arg)

    import Ecto.Query

    if not opts[:debug_logging] do
      Logger.put_process_level(self(), :info)
    end

    # Cleanup old runners
    repo.delete_all(
      from(
        r in OffBroadwayPostgres.Model.Runner,
        where: r.heartbeat < fragment("(now() - interval '60 second')")
      )
    )

    # Create runner row for this producer
    runner_id = insert_runner(repo)

    Process.send_after(self(), :heartbeat, 10_000)

    polling_ref = make_ref()
    {:ok, polling_timer} = :timer.send_after(opts[:polling_interval], {:poll, polling_ref})

    pipeline_name = opts[:name]
    if opts[:join_pg] do
      scope = opts[:pg_scope]

      if :ets.whereis(scope) == :undefined do
        Logger.error("join_pg: true is set in producer options, but the pg scope `#{scope}` has not been started")
      end

      group_name = OffBroadwayPostgres.pg_name(pipeline_name)
      :ok = :pg.join(scope, group_name, self())
    end

    {:producer,
     %{
       runner_id: runner_id,
       batch_idx: 0,
       demand: 0,
       pipeline_name: pipeline_name,
       message_fetch_count: opts[:message_fetch_count],
       source: opts[:source],
       polling_interval: opts[:polling_interval],
       polling_ref: polling_ref,
       polling_timer: polling_timer
     }}
  end

  @impl Broadway.Producer
  def prepare_for_start(_module, broadway_opts) do
    {producer_module, raw_opts} = broadway_opts[:producer][:module]

    opts = NimbleOptions.validate!(raw_opts, Options.definition())

    broadway_opts = put_in(broadway_opts, [:producer, :module], {producer_module, opts})

    {[], broadway_opts}
  end

  @impl Broadway.Producer
  def prepare_for_draining(state) do
    {:noreply, [], state}
  end

  @impl GenStage
  def handle_demand(demand, state) do
    import Ecto.Query

    state = %{
      state
      | demand: state.demand + demand
    }

    {messages, state} = fetch_demand(state)
    {:noreply, messages, state}
  end

  def fetch_demand(state) do
    import Ecto.Query

    state = %{
      state
      | batch_idx: state.batch_idx + 1
    }

    to_claim_num = max(state.message_fetch_count, state.demand)
    runner_col = {state.runner_id, state.batch_idx}

    {:ok, claimed} = claim_jobs(state.source, runner_col, to_claim_num)

    messages =
      Enum.map(claimed, fn item ->
        %Broadway.Message{
          data: item,
          acknowledger: Broadway.CallerAcknowledger.init({self(), nil}, :ignored)
        }
      end)

    state = %{
      state
      | demand: max(state.demand - Enum.count(messages), 0)
    }

    {messages, state}
  end

  @impl GenStage
  def handle_info(:heartbeat, state) do
    {source_mod, source_arg} = state.source
    repo = source_mod.repo(source_arg)

    import Ecto.Query

    repo.update_all(
      from(
        j in OffBroadwayPostgres.Model.Runner,
        where: j.id == ^state.runner_id,
        update: [set: [heartbeat: fragment("now()")]]
      ),
      []
    )

    Process.send_after(self(), :heartbeat, 10_000)

    {:noreply, [], state}
  end

  @impl GenStage
  def handle_info({:ack, nil, successful, failed}, state) do
    import Ecto.Query, only: [from: 2]
    import OffBroadwayPostgres.Ecto.Util, only: [values: 1]

    :ok = finish_jobs(state.source, state.pipeline_name, successful, failed)

    {:noreply, [], state}
  end

  @impl GenStage
  def handle_info({:poll, poll_ref}, %{polling_ref: poll_ref} = state) do
    {messages, state} = poll_if_demand(state)

    polling_ref = make_ref()
    {:ok, polling_timer} = :timer.send_after(state.polling_interval, {:poll, polling_ref})

    state = %{state |
      polling_ref: polling_ref,
      polling_timer: polling_timer
    }

    {:noreply, messages, state}
  end

  @impl GenStage
  def handle_info({:poll, _poll_ref}, state) do
    {:noreply, [], state}
  end

  def handle_info(:poll, state) do
    {messages, state} = poll_if_demand(state)
    {:noreply, messages, state}
  end

  def poll_if_demand(state) do
    if state.demand > 0 do
      fetch_demand(state)
    else
      {[], state}
    end
  end

  def insert_runner(repo) do
    runner_result =
      repo.query!(
        "INSERT INTO off_broadway_postgres_runners(heartbeat) VALUES (now()) RETURNING id;"
      )

    [runner_row] = runner_result.rows
    runner = repo.load(OffBroadwayPostgres.Model.Runner, {runner_result.columns, runner_row})
    runner_id = runner.id

    if runner_id == nil do
      raise "runner id was nil"
    end

    runner_id
  end

  def claim_jobs({source_mod, source_arg}, {_, _} = runner_col, to_claim_num) do
    import Ecto.Query

    apply_claimed_filter = fn query, job_source, job_field, job_runner_field ->
      from(
        q in query,
        left_join: runner in subquery(OffBroadwayPostgres.Model.Runner.active_runners_query()),
        on: fragment("((?).runner_id)", field(as(^job_source), ^job_runner_field)) == runner.id,
        left_join: job in OffBroadwayPostgres.Model.Job,
        on: field(as(^job_source), ^job_field) == job.id,
        where: is_nil(runner.id) and (is_nil(job.id) or job.status == :retry)
      )
    end

    source_mod.claim_jobs(
      runner_col,
      apply_claimed_filter,
      to_claim_num,
      source_arg
    )
  end

  def finish_jobs({source_mod, source_arg}, pipeline_name, successful, failed) do
    import Ecto.Query, only: [from: 2]
    import OffBroadwayPostgres.Ecto.Util, only: [values: 1]

    repo = source_mod.repo(source_arg)

    # Return value for successful jobs:
    # Job ID is nulled.
    successful_updates = Enum.map(successful, &{&1.data, nil})

    # When a job fails, there are two distinct codepaths:
    # * There is no existing job row.
    #   In this case we need to insert a new row in the jobs table with the error logged.
    # * There is an existing job row.
    #   In this case we need to update the attempt, and either fail or put the job in a retry state.
    grouped_fails =
      failed
      |> Enum.map(&{&1, source_mod.get_job_id(&1.data, source_arg)})
      |> Enum.group_by(fn {_item, job_id} -> job_id != nil end)

    with_job = Map.get(grouped_fails, true, [])
    without_job =
      Map.get(grouped_fails, false, [])
      |> Enum.map(fn {id, nil} -> id end)

    repo.transaction(fn ->
      # Path 1: Failed jobs WITH existing job rows.
      # Append error, increment attempt, potentially put into fail state.
      {errors, with_job_ids} =
        with_job
        |> Enum.map(fn {msg, job_id} ->
          {format_error(msg.status), job_id}
        end)
        |> Enum.unzip()

      # TODO backoff
      repo.update_all(
        from(
          j in OffBroadwayPostgres.Model.Job,
          inner_join:
            sub in values(
              id: type(^with_job_ids, {:array, :integer}),
              error: type(^errors, {:array, :string})
            ),
          on: j.id == sub.id,
          update: [
            set: [
              status:
                fragment(
                  """
                  CASE
                    WHEN ? >= 3 THEN 'failed'
                    ELSE 'retry'
                  END
                  """,
                  j.attempt
                )
            ],
            push: [
              errors: sub.error
            ],
            inc: [
              attempt: 1
            ]
          ]
        ),
        []
      )

      # Return value for path 1:
      # Strictly speaking no change in the source table.
      # Job ID is same as before.
      with_job_updates = Enum.map(with_job, fn {msg, job_id} -> {msg.data, job_id} end)

      # Path 2: Failed jobs WITHOUT existing job rows.
      # Insert new job rows.
      job_maps =
        Enum.map(
          without_job,
          fn item ->
            error = format_error(item.status)

            %{
              status: :retry,
              attempt: 1,
              errors: [error],
              pipeline_name: Atom.to_string(pipeline_name)
            }
          end
        )

      {_count, jobs} =
        repo.insert_all(
          OffBroadwayPostgres.Model.Job,
          job_maps,
          returning: [:id]
        )

      # Return value for path 2:
      # Job ID is the newly inserted Job ID.
      without_job_updates =
        Enum.zip(without_job, jobs)
        |> Enum.map(fn {msg, job} -> {msg.data, job.id} end)

      # All finished jobs are updated with their new Job IDs.
      updates =
        Enum.concat([
          with_job_updates,
          without_job_updates,
          successful_updates
        ])
      source_mod.update_jobs(updates, source_arg)
    end)

    :ok
  end

  def format_error({kind, reason, stacktrace}) do
    {blamed, stacktrace} = Exception.blame(kind, reason, stacktrace)
    Exception.format(kind, blamed, stacktrace)
  end

  def format_error({:error, error}) do
    inspect(error)
  end
end
