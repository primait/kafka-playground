defmodule ElixirBrod.MixProject do
  use Mix.Project

  def project do
    [
      app: :elixir_brod,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

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
      {:brod, "~> 3.17.0"}
    ]
  end
end
