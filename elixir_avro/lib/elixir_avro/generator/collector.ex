defmodule ElixirAvro.Generator.Collector do
  # This is not pure, since it uses ets underneath,
  # but with some effort we can make it pure if we really want to.
  def collect(erlavro_schema_parsed) do
    {:ok, %Avrora.Schema{lookup_table: lookup_table}} =
      ElixirAvro.AvroraClient.Schema.Encoder.from_erlavro(erlavro_schema_parsed)

    :avro_schema_store.get_all_types(lookup_table)
    |> Enum.map(&{:avro.get_type_fullname(&1), &1})
    |> Enum.into(%{})
  end
end
