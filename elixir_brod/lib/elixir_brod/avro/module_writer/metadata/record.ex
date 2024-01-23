defimpl ElixirBrod.Avro.ModuleWriter.Metadata, for: ElixirBrod.Avro.SchemaParser.Record do
  alias ElixirBrod.Avro.SchemaParser.Field

  import ElixirBrod.Avro.ModuleWriter.Conventions

  require EEx

  @primitive_type_map %{
    boolean: "boolean()",
    bytes: "binary()",
    double: "float()",
    float: "float()",
    int: "integer()",
    long: "integer()",
    null: "nil",
    string: "String.t()"
  }

  @logical_type_map %{
    "local-timestamp-micros": "NaiveDateTime.t()",
    "local-timestamp-millis": "NaiveDateTime.t()",
    "time-micros": "Time.t()",
    "time-millis": "Time.t()",
    "timestamp-micros": "DateTime.t()",
    "timestamp-millis": "DateTime.t()",
    date: "Date.t()",
    duration: "ElixirBrod.Avro.Duration.t()",
    uuid: "UUid.t()",
    decimal: "Decimal.t()"
  }

  @primitive_types Map.keys(@primitive_type_map)

  @logical_types Map.keys(@logical_type_map)

  @simple_types @primitive_types ++ @logical_types

  @complex_types [
    :array,
    :map
  ]

  EEx.function_from_file(
    :def,
    :to_string,
    "priv/templates/record.ex",
    [:metadata],
    trim: true
  )

  @spec parse_field_type(atom()) :: String.t()
  defp parse_field_type(%Field{name: name, type: type} = field),
    do: "#{String.replace(name, ~r/\s/, "_")}: #{elixir_type_from_avro_field(type, field)}"

  defp elixir_type_from_avro_field(_type, %Field{logical_type: logical})
       when logical in @logical_types,
       do: "#{Map.fetch!(@logical_type_map, logical)}"

  defp elixir_type_from_avro_field(type, _field) when type in @primitive_types,
    do: "#{Map.fetch!(@primitive_type_map, type)}"

  defp elixir_type_from_avro_field(types, field) when is_list(types) do
    types
    |> Enum.map(&elixir_type_from_avro_field(&1, field))
    |> Enum.join(" | ")
  end

  defp elixir_type_from_avro_field(:array, %Field{items: items}) do
    types =
      items
      |> Enum.map(&elixir_type_from_avro_field(&1, nil))
      |> Enum.join(" | ")

    "[#{types}]"
  end

  defp elixir_type_from_avro_field(:map, %Field{items: items}) do
    types =
      items
      |> Enum.map(&elixir_type_from_avro_field(&1, nil))
      |> Enum.join(" | ")

    "%{String.t() => #{types}}"
  end

  defp elixir_type_from_avro_field(:fixed, %Field{size: size}),
    do: "<<_::#{size * 8}>>"

  defp elixir_type_from_avro_field(%Field{name: name}, _field),
    do: String.replace(name, ~r/\s/, "_")

  defp validate(%Field{name: name, type: type} = definition) when type in @simple_types,
    do:
      "ElixirBrod.Avro.Validation.Simple.validate(#{inspect(String.to_existing_atom(name))}, #{inspect(definition)})"

  defp validate(%Field{name: name, type: type} = definition)
       when type in @complex_types or is_list(type),
       do:
         "ElixirBrod.Avro.Validation.Complex.validate(#{inspect(String.to_existing_atom(name))}, #{inspect(definition)})"
end
