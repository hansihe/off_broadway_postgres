defmodule OffBroadwayPostgres.Util do
  import Ecto.Query

  def job_stats(query, repo, job_id, is_finished) do

    stats =
      repo.all(
        query
        |> join(:left, [], j in OffBroadwayPostgres.Model.Job,
          as: :job,
          on: ^dynamic([job: j], j.id == ^job_id)
        )
        |> group_by(^[dynamic([job: j], j.status), is_finished])
        |> select(
          ^%{
            status: dynamic([job: j], j.status),
            finished: is_finished,
            count: dynamic(count())
          }
        )
      )

    data =
      stats
      |> Enum.group_by(
        fn
          %{finished: true} -> :done
          %{status: nil, finished: false} -> :pending
          %{status: :failed} -> :failed
          %{status: :retry} -> :retry
        end,
        fn %{count: count} -> count end
      )
      |> Enum.map(fn {key, val} -> {key, Enum.sum(val)} end)

    struct!(%OffBroadwayPostgres.SourceStatistics.Stats{}, data)
  end

  def failed_for_pipeline(pipeline_name) do
    from(
      j in OffBroadwayPostgres.Model.Job,
      where: j.pipeline_name == ^pipeline_name
    )
  end
end
