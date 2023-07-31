defmodule OffBroadwayPostgres.Producer.Scheduler do
  # Separate features:
  # * Polling period timer - default 10 seconds
  # * Demand request deduplication
  # * Notification debouncing - default 0.1 second

  defstruct [
    polling_period: 10_000,
    demand_debounce: :once,
    notify_debounce: 100,

    seen_demand: false,
  ]

  def new do
    state = %__MODULE__{}
    {state, false, state.polling_period}
  end

  def timer_expired(state, _now) do
    state
  end

  def on_demand(state, _now) do
    case state.demand_debounce do
      :once ->
        should_poll = not state.seen_demand
        state = %{state | seen_demand: true}
        {state, should_poll, state.polling_period}

      #time when is_number(time) ->

    end
  end

end
