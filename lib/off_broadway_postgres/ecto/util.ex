defmodule OffBroadwayPostgres.Ecto.Util do
  defmacro values(columns) do
    if not is_list(columns) do
      raise "expected keyword list"
    end

    Enum.each(columns, fn
      {key, _val} when is_atom(key) -> true
      _ -> raise "expected keyword list"
    end)

    num_cols = Enum.count(columns)

    if num_cols < 1 do
      raise "expected at least one column"
    end

    unnest_args =
      columns
      |> Enum.map(fn _ -> "?" end)
      |> Enum.join(",")

    column_names =
      columns
      |> Enum.map(fn {k, _} -> to_string(k) end)
      |> Enum.join(",")

    column_vars =
      columns
      |> Enum.map(fn {_, v} -> v end)

    fragment_str = "SELECT * FROM UNNEST(#{unnest_args}) AS f(#{column_names})"

    quote do
      fragment(unquote(fragment_str), unquote_splicing(column_vars))
    end
  end
end
