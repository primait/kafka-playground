defmodule ElixirAvro.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ElixirAvro.AvroraClient
    ]

    opts = [strategy: :one_for_one, name: ElixirBrod.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
