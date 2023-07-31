defmodule OffBroadwayPostgres.SimpleSource do

  defmacro __using__(opts) do
    repo = Keyword.fetch!(opts, :repo)
    schema = Keyword.fetch!(opts, :schema)
    claimable = Keyword.fetch!(opts, :claimable)
    id_field = Keyword.get(opts, :id_field, :id)
    job_id_field = Keyword.fetch!(opts, :job_id_field)
    job_runner_field = Keyword.fetch!(opts, :job_runner_field)

    quote do
      @behaviour OffBroadwayPostgres.Source

      @impl true
      def repo(_arg) do
        unquote(repo)
      end

      @impl true
      def claim_jobs(runner, filter_fn, claim_count, _arg) do
        claimable_cond = unquote(claimable)

        claimable_query =
          from(
            s in unquote(schema),
            as: :s,
            where: ^claimable_cond,
            limit: ^claim_count,
            lock: fragment("FOR UPDATE OF ? SKIP LOCKED", s)
          )
          |> filter_fn.(:s, unquote(job_id_field), unquote(job_runner_field))

        {_count, items} =
          from(
            u in unquote(schema),
            inner_join: iq in subquery(claimable_query),
            on: u.unquote(id_field) == iq.unquote(id_field),
            update: [set: [{unquote(job_runner_field), ^runner}]],
            select: u
          )
          |> unquote(repo).update_all([])

        {:ok, Enum.map(items, &%{item: &1})}
      end

      @impl true
      def get_job_id(item, _arg) do
        item.item.unquote(job_id_field)
      end

      @impl true
      def update_jobs(items, _arg) do
        OffBroadwayPostgres.Source.update_on_id(
          items,
          unquote(schema),
          unquote(id_field),
          unquote(job_id_field),
          unquote(job_runner_field),
          fn item -> item.item.unquote(id_field) end
        )
        |> CX.Repo.update_all([])

        :ok
      end

    end
  end

end