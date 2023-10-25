import Config

config :brod,
  clients: [
    kafka_client: [endpoints: [{~c"kafka", 9092}], auto_start_producers: true]
  ]

config :elixir_brod,
  source_topic: System.fetch_env!("SOURCE"),
  destination_topic: System.fetch_env!("DESTINATION")
