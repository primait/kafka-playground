import Config

config :brod,
  clients: [
    kafka_client: [endpoints: [{~c"kafka", 9092}], auto_start_producers: true]
  ]
