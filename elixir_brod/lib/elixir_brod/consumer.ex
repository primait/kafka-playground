defmodule ElixirBrod.Consumer do
  require Logger
  require OpenTelemetry.Tracer
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

  @producer Application.compile_env(:elixir_brod, :producer_module, :brod)

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
  def handle_message(kafka_message(value: value, headers: headers) = message, state) do
    :otel_propagator_text_map.extract(headers)
    parent = OpenTelemetry.Tracer.current_span_ctx()

    link = OpenTelemetry.link(parent)
    
    OpenTelemetry.Ctx.clear()
    
    OpenTelemetry.Tracer.with_span :consume, %{links: [link]} do
      OpenTelemetry.Tracer.with_span :internal do
        Logger.info("message consumed: #{inspect(message)}")

        OpenTelemetry.Tracer.with_span :producer do
          @producer.produce_sync(
            :kafka_client,
            Keyword.fetch!(state, :destination_topic),
            :random,
            "",
            %{value: value, headers: :otel_propagator_text_map.inject([])}
          )
        end

        {:ok, :commit, state}
      end
    end
  end
end
