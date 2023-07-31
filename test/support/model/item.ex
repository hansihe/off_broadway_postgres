defmodule OffBroadwayPostgres.Test.Model.Item do
  use Ecto.Schema

  schema "items" do
    field :done, :boolean
    field :job_id, :integer
    field :job_runner, OffBroadwayPostgres.Ecto.Runner
  end
end
