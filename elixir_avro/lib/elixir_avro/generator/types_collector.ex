defmodule ElixirAvro.Generator.TypesCollector do
  # This is not pure, since it uses ets underneath,
  # but with some effort we can make it pure if we really want to.
  def collect(erlavro_schema_parsed, read_schema_fun) do
    {:ok, %Avrora.Schema{lookup_table: lookup_table}} =
      ElixirAvro.AvroraClient.Schema.Encoder.from_erlavro(erlavro_schema_parsed)

    add_references(erlavro_schema_parsed, lookup_table, read_schema_fun)

    :avro_schema_store.get_all_types(lookup_table)
    |> Enum.map(&{:avro.get_type_fullname(&1), &1})
    |> Enum.into(%{})
  end

  defp add_references(erlavro_schema_parsed, lookup_table, read_schema_fun) do
    {:ok, refs} = Avrora.Schema.ReferenceCollector.collect(erlavro_schema_parsed)

    refs
    |> Enum.map(&read_schema_fun.(&1))
    |> Enum.map(&:avro_json_decoder.decode_schema(&1, allow_bad_references: true))
    |> Enum.map(&:avro_schema_store.add_type(&1, lookup_table))
  end
end
