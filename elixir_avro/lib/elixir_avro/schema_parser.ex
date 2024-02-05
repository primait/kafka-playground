defmodule ElixirAvro.SchemaParser do
  # avoid to overwrite same types and break if the defitions are different, check if add_type already does it
  # apparently there is `allow_type_redefine`, let's test if it works as expected


  # This is not pure, since it uses ets underneath,
  # but with some effort we can make it pure if we really want to.
  def parse(root_schema_content, read_schema_fun) do
    erlavro_schema_parsed =
      :avro_json_decoder.decode_schema(root_schema_content, allow_bad_references: true)

    lookup_table = :avro_schema_store.new()
    :avro_schema_store.add_type(erlavro_schema_parsed, lookup_table)

    add_references_types(erlavro_schema_parsed, lookup_table, read_schema_fun)

    :avro_schema_store.get_all_types(lookup_table)
    |> Enum.map(&{:avro.get_type_fullname(&1), &1})
    |> Enum.into(%{})
  end

  defp add_references_types(erlavro_schema_parsed, lookup_table, read_schema_fun) do
    # TODO Should we copy the implementation of ReferenceCollector?
    {:ok, refs} = Avrora.Schema.ReferenceCollector.collect(erlavro_schema_parsed)

    refs
    |> Enum.map(&read_schema_fun.(&1))
    |> Enum.map(&:avro_json_decoder.decode_schema(&1, allow_bad_references: true))
    |> Enum.map(&:avro_schema_store.add_type(&1, lookup_table))
  end
end
