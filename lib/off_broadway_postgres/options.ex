defmodule OffBroadwayPostgres.Options do
  @moduledoc false

  definition = [
    name: [
      doc:
        "The name of the source. This should be unique for the source query as it's used to identify the pipeline in the jobs table.",
      required: true,
      type: :atom
    ],
    source: [
      doc:
        "The source for jobs. This should be a module that implements the `OffBroadwayPostgres.Source` behaviour.",
      required: true,
      type: :mod_arg
    ],
    message_fetch_count: [
      doc: "The default number of messages to claim at a time.",
      type: :pos_integer,
      default: 100
    ],
    polling_interval: [
      doc: """
      The interval at which the database will be polled (in milliseconds).
      Can also be `nil` to disable interval polling.
      """,
      type: {:or, [:pos_integer, {:in, [nil]}]},
      default: 60_000
    ],
    demand_debounce: [
      doc: """
      In a pipeline with multiple processors, multiple demand requests can
      arrive in rapid succession. If there are no available jobs in the DB,
      this can cause multiple unnecessary job claim queries.

      This option sets a debounce timer for demand requests.
      Can be either a positive number of milliseconds, or `nil`.
      """,
      type: {:or, [:pos_integer, {:in, [nil]}]},
      default: 1_000
    ],
    debug_logging: [
      doc: """
      Enables debug level logging for the producer.
      """,
      type: :boolean,
      default: false
    ],
    join_pg: [
      doc: """
      Whether to join a pg group. This can be used to send notifications
      to producers.
      """,
      type: :boolean,
      default: true
    ],
    pg_scope: [
      type: :atom,
      default: :pg
    ]
  ]

  @definition NimbleOptions.new!(definition)

  def definition do
    @definition
  end
end
