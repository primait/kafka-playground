defmodule ElixirAvro.Generator.Typedstruct do
  @primitive_types_mapping %{
    "boolean" => "boolean()",
    "int" => "integer()",
    "long" => "integer()",
    "float" => "float()",
    "double" => "float()",
    "bytes" => "String.t()",
    "string" => "String.t()"
  }

  @primitive_types Map.keys(@primitive_types_mapping)

  @null_type {:avro_primitive_type, "null", []}

  @doc """
  Generates the code-snip with the typespec of the given field. This also adds
  an `enforce: true` typedstruct option when the field is not nullable.
  """
  @spec spec_for(erlavro_field :: tuple()) :: String.t()
  def spec_for(
        {:avro_record_field, _name, _doc, {:avro_primitive_type, primitive_type, []}, _default,
         _ordering, _aliases}
      )
      when primitive_type in @primitive_types do
    "#{get_spec_for_primitive(primitive_type)}, enforce: true"
  end

  def spec_for(
        {:avro_record_field, _name, _doc,
         {:avro_primitive_type, "string", [{"logicalType", "uuid"}]}, _default, _ordering,
         _aliases}
      ) do
    "String.t(), enforce: true"
  end

  def spec_for(
        {:avro_record_field, _name, _doc,
         {:avro_primitive_type, "int", [{"logicalType", "date"}]}, _default, _ordering, _aliases}
      ) do
    "Date.t(), enforce: true"
  end

  def spec_for(
        {:avro_record_field, _name, _doc, {:avro_union_type, _, _} = union_type, _default,
         _ordering, _aliases}
      ) do
    # when all groups of functions will be moved to a dedicated module, strip_null_fun can become a private function
    strip_null_fun = fn types ->
      if @null_type in types do
        {"", List.delete(types, @null_type)}
      else
        {", enforce: true", types}
      end
    end

    {append_spec, types} = union_type |> :avro_union.get_types() |> strip_null_fun.()

    # TODO this works just for primitive types right now
    types
    |> Enum.map(fn {:avro_primitive_type, primitive_type, []} -> primitive_type end)
    |> Enum.map(&get_spec_for_primitive/1)
    |> Enum.join(" | ")
    |> Kernel.<>(append_spec)
  end

  defp get_spec_for_primitive(primitive_type) do
    Map.fetch!(@primitive_types_mapping, primitive_type)
  end
end
