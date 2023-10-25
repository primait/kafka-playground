defmodule ElixirBrod.Consumer do
  require Logger
  require Record

  Record.defrecord(
    :kafka_message_set,
    Record.extract(:kafka_message_set, from_lib: "brod/include/brod.hrl")
  )

  Record.defrecord(
    :kafka_message,
    Record.extract(:kafka_message, from_lib: "brod/include/brod.hrl")
  )

  defstruct [:destination_topic]

  @behaviour :brod_group_subscriber_v2

  def child_spec([source_topic, destination_topic]) do
    config = %{
      client: :kafka_client,
      group_id: "elixir",
      topics: [source_topic],
      cb_module: __MODULE__,
      consumer_config: [{:begin_offset, :latest}],
      init_data: [destination_topic: destination_topic],
      message_type: :message
    }

    %{
      id: __MODULE__,
      start: {:brod_group_subscriber_v2, :start_link, [config]},
      type: :worker,
      restart: :temporary,
      shutdown: 5000
    }
  end

  @impl :brod_group_subscriber_v2
  def init(_group_id, init_data), do: {:ok, init_data}

  @impl :brod_group_subscriber_v2
  def handle_message(kafka_message(value: value) = message, state) do
    Logger.info("message consumed: #{inspect(message)}")
    :brod.produce_sync(:kafka_client, Keyword.fetch!(state, :destination_topic), 0, "", value)
    {:ok, :commit, state}
  end
end
