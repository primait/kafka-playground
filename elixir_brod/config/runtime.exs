import Config

config :brod,
  clients: [
    kafka_client: [endpoints: [{~c"kafka", 9092}], auto_start_producers: true]
  ]

config :elixir_brod,
  source_topic: System.fetch_env!("SOURCE"),
  destination_topic: System.fetch_env!("DESTINATION")

config :opentelemetry, :processors,
       otel_batch_processor: %{
         exporter:
           {:opentelemetry_exporter,
            %{
              endpoints: [
                {:http, "jaeger", 55681, []}
              ]
            }}
       }

config :opentelemetry, :resource,
       "deployment.environment": config_env(),
       "service.name": "elixir_brod" 
