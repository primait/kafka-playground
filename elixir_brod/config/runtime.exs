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

config :avrora,
  # optional, if you want to use it as a root folder for `schemas_path`
  otp_app: :elixir_brod,
  schemas_path: "../../../../schemas"

# registry_url: "http://localhost:8081",
# # optional
# registry_auth: {:basic, ["username", "password"]},
# # optional: if you want to return previous behaviour, set it to `nil`
# registry_user_agent: "Avrora/0.24.2 Elixir",
# # optional: if you want manually register schemas
# registry_schemas_autoreg: false,
# # optional: if you want to keep decoded `:null` values as is
# convert_null_values: false,
# # optional: if you want to restore the old behavior for decoding map-type
# convert_map_to_proplist: false,
# # optional: if you want periodic disk reads
# names_cache_ttl: :timer.minutes(5),
# # optional: if you want to amend the data/result
# decoder_hook: &MyClient.decoder_hook/4
