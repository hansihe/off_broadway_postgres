defmodule OffBroadwayPostgres.Source do
  @moduledoc """
  Implementors of this behaviour specify a DB source for a broadway pipeline.

  Implementors are given a great amount of flexibility as to how this is done,
  but a few expectations apply:
  * The `job_runner` and `job_id` tracking fields should be present in
    a table which indicates the unit of work.
  * When jobs are finished, they should no longer appear in the query
    you use to claim jobs in `claim_jobs`.


  """

  @type source_arg :: term()

  @type column :: atom()
  @type job_id :: pos_integer() | nil

  @type apply_claimed_filter_fn :: (Ecto.Query.t(), column(), column() -> Ecto.Query.t())

  @type count :: pos_integer()

  @type item :: term()

  @type runner_or_nil :: OffBroadwayPostgres.Ecto.Runner.t() | nil

  @doc """
  Returns the ecto repo this source applies to.
  """
  @callback repo(source_arg()) :: module()

  @doc """
  Claims up to `count` available jobs by:
  * Setting the runner field to the `runner` value.
  * Returning the list of `item`s claimed.

  It is up to the implementer to construct the query. `apply_claimed_filter_fn`
  should be applied to the query in order to filter out any jobs that have already
  been started.

  **Important**: When a job has gone through the broadway pipeline,
  any given job should no longer appear in the query. This is usually
  by a flag, but can also be done by a join to a results table. See
  examples above.
  """
  @callback claim_jobs(
              runner :: OffBroadwayPostgres.Ecto.Runner.t(),
              filter_fn :: apply_claimed_filter_fn(),
              claim_count :: count(),
              source_arg()
            ) :: {:ok, [item()]}

  @doc """
  Given an item (term returned by `claim_jobs/3`), returns the job id
  that is associated with it. If the item has not previously been
  associated with any job through a call to `associate_jobs/3`,
  this should return `nil`.
  """
  @callback get_job_id(item(), source_arg()) :: job_id()

  @doc """
  Should set the job and runner fields of the given items.
  """
  @callback update_jobs([{item(), job_id()}], source_arg()) :: :ok

  def update_on_id(items, model, id_col, job_id_col, runner_col, id_mapper) do
    import Ecto.Query
    import OffBroadwayPostgres.Ecto.Util, only: [values: 1]

    ids = Enum.map(items, fn {item, _job_id} -> id_mapper.(item) end)
    job_ids = Enum.map(items, fn {_item, job_id} -> job_id end)

    from(
      m in model,
      inner_join:
        sub in values(
          id: type(^ids, {:array, :integer}),
          job_id: type(^job_ids, {:array, :integer})
        ),
      on: field(m, ^id_col) == sub.id,
      update: [
        set: [
          {^job_id_col, sub.job_id},
          {^runner_col, nil}
        ]
      ]
    )
  end
end
