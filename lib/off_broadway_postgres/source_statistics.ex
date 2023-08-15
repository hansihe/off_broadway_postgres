defmodule OffBroadwayPostgres.SourceStatistics do
  @moduledoc """
  Implementors of this behaviour should also implement
  `OffBroadwayPostgres.Source`.
  """

  defmodule Stats do
    defstruct [
      done: 0,
      pending: 0,
      failed: 0,
      retry: 0
    ]

    @type t :: %__MODULE__{}
  end

  @callback get_stats(source_arg :: OffBroadwayPostgres.Source.source_arg()) :: Stats.t()

end
