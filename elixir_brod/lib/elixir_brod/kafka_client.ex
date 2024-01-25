defmodule ElixirBrod.KafkaClient do
  use Avrora.Client,
    otp_app: :elixir_brod,
    schemas_path: "./schemas"
    # registry_url: "http://localhost:8081",
    # registry_auth: {:basic, ["username", "password"]},
    # registry_user_agent: "Avrora/0.25.0 Elixir",
    # registry_schemas_autoreg: false,
    # convert_null_values: false,
    # convert_map_to_proplist: false,
    # names_cache_ttl: :timer.minutes(5),
    # decoder_hook: &MyClient.decoder_hook/4
end
