# credo:disable-for-this-file
# defmodule OffBroadwayPostgres.Manager do
#  @behaviour Postgrex.SimpleConnection
#
#  alias Postgrex.SimpleConnection, as: Simple
#
#  @doc false
#  def child_spec(opts) do
#    #conf = Keyword.fetch!(opts, :conf)
#    #opts = Keyword.put_new(opts, :name, conf.notifier)
#
#    %{id: opts[:name], start: {__MODULE__, :start_link, [opts]}}
#  end
#
#  def start_link(opts) do
#    repo = CX.Repo
#
#    conn_opts =
#      repo.config()
#      |> Keyword.put(:name, opts[:name])
#      |> Keyword.put_new(:auto_reconnect, false)
#      |> Keyword.put_new(:sync_connect, true)
#
#    Simple.start_link(__MODULE__, [], conn_opts)
#  end
#
#  @impl Simple
#  def init(opts) do
#    state = %{
#      state: nil,
#      runner_id: nil
#    }
#    {:ok, state}
#  end
#
#  @impl Simple
#  def handle_connect(state) do
#    query = """
#    DELETE FROM off_broadway_postgres_runners WHERE heartbeat < (now() - interval '60 second');
#    INSERT INTO off_broadway_postgres_runners(heartbeat) VALUES (now()) RETURNING id;
#    """
#    state = %{
#      state |
#      state: :await_insert
#    }
#    {:query, query, state}
#  end
#
#  def handle_disconnect(state) do
#    exit(:manager_disconnected)
#  end
#
#  @impl true
#  def handle_info(:heartbeat, state) do
#    query = """
#    UPDATE off_broadway_postgres_runners SET heartbeat = CURRENT_TIMESTAMP WHERE id = #{state.runner_id};
#    """
#    state = %{
#      state |
#      state: :await_heartbeat,
#    }
#    {:query, query, state}
#  end
#
#  @impl true
#  def handle_result(result, %{state: :await_insert} = state) do
#    [
#      %Postgrex.Result{},
#      %Postgrex.Result{
#        columns: ["id"],
#        rows: [[runner_id_str]],
#      }
#    ] = result
#    {runner_id, ""} = Integer.parse(runner_id_str)
#
#    state = %{
#      state |
#      state: nil,
#      runner_id: runner_id
#    }
#
#    Process.send_after(self(), :heartbeat, 10_000)
#    {:noreply, state}
#  end
#
#  def handle_result(result, %{state: :await_heartbeat} = state) do
#    [
#      %Postgrex.Result{}
#    ] = result
#
#    state = %{
#      state |
#      state: nil
#    }
#
#    Process.send_after(self(), :heartbeat, 10_000)
#    {:noreply, state}
#  end
#
# end
#
