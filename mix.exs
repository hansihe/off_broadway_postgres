defmodule OffBroadwayPostgres.MixProject do
  use Mix.Project

  def project do
    [
      app: :off_broadway_postgres,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ecto_sql, "~> 3.10"},
      {:broadway, "~> 1.0.7"},
      {:postgrex, "~> 0.17"}
    ]
  end
end