defimpl ElixirBrod.Avro.ModuleWriter.Metadata, for: ElixirBrod.Avro.SchemaParser.MessageEnum do
  require EEx

  EEx.function_from_file(
    :def,
    :to_string,
    "priv/templates/enum.ex",
    [:metadata]
  )
end
