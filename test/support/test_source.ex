defmodule OffBroadwayPostgres.Test.Source do
  import Ecto.Query

  use OffBroadwayPostgres.SimpleSource,
    repo: OffBroadwayPostgres.Test.Repo,
    schema: OffBroadwayPostgres.Test.Model.Item,
    claimable: dynamic([i], not i.done),
    job_id_field: :job_id,
    job_runner_field: :job_runner

end
