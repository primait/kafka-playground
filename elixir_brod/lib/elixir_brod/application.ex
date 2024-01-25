defmodule ElixirBrod.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {ElixirBrod.Consumer,
       [
         Application.fetch_env!(:elixir_brod, :source_topic),
         Application.fetch_env!(:elixir_brod, :destination_topic)
      ]},
      ElixirBrod.KafkaClient,
      Avrora
    ]

    opts = [strategy: :one_for_one, name: ElixirBrod.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
