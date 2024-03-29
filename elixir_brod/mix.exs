defmodule ElixirBrod.MixProject do
  use Mix.Project

  def project do
    [
      app: :elixir_brod,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  def aliases, do: [start: ["deps.get", "run --no-halt"]]
  
  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {ElixirBrod.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:brod, "~> 3.17.0"},
      {:opentelemetry, "~> 1.3.1"},
      {:opentelemetry_exporter, "~> 1.6.0"},
      {:opentelemetry_api, "~> 1.2.2"}
    ]
  end
end
