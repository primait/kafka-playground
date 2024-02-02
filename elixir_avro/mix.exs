defmodule ElixirAvro.MixProject do
  use Mix.Project

  def project do
    [
      app: :elixir_avro,
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
      mod: {ElixirAvro.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:avrora, "~> 0.21"},
      {:excribe, "~> 0.1.1"},
      {:typed_struct, "~> 0.3.0"}
    ]
  end
end
