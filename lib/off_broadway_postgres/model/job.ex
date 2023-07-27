defmodule OffBroadwayPostgres.Model.Job do
  use Ecto.Schema

  schema "off_broadway_postgres_jobs" do
    field :errors, {:array, :string}
    field :attempt, :integer
    field :status, Ecto.Enum, values: [:failed, :retry]
    field :pipeline_name, :string
  end
end
