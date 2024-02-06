defmodule ElixirAvro.Generator.Types do
  @moduledoc """
  This module contains utility functions for conversion and typesecs of avro
  types from and into elixir types.
  """

  # alias ElixirBrod.Avro.ModuleWriter.Conventions

  # see: https://avro.apache.org/docs/1.11.0/spec.html#schema_primitive
  @primitive_type_spec_strings %{
    "null" => "nil",
    "boolean" => "boolean()",
    "int" => "integer()",
    "long" => "integer()",
    "float" => "float()",
    "double" => "float()",
    "bytes" => "binary()",
    "string" => "String.t()"
  }

  # see: https://avro.apache.org/docs/1.11.0/spec.html#Logical+Types
  @logical_types_spec_strings %{
    {"bytes", "decimal"} => "Decimal.t()",
    {"string", "uuid"} => "String.t()",
    {"int", "date"} => "Date.t()",
    {"int", "time-millis"} => "Time.t()",
    {"long", "time-micros"} => "Time.t()",
    {"long", "timestamp-millis"} => "DateTime.t()",
    {"long", "timestamp-micros"} => "DateTime.t()",
    {"long", "local-timestamp-millis"} => "NaiveDateTime.t()",
    {"long", "local-timestamp-micros"} => "NaiveDateTime.t()"
    # avro specific custom implemented duration (incompatible with Timex.Duration) - leaving it out for the moment
    # {"fixed", "duration"} => "ElixirBrod.Avro.Duration.t()"
  }

  def to_typedstruct_spec!(type, module_prefix) do
    to_spec_string!(type, module_prefix) <> ", enforce: #{enforce?(type)}"
  end

  def enforce?({:avro_union_type, _, _}) do
    false
  end

  def enforce?(_type) do
    true
  end

  @doc ~S"""
  Returns the string to be used as elixir type for any avro type.

  # Examples

  ## Primitive types

  iex> to_spec_string!({:avro_primitive_type, "boolean", []}, "my_prefix")
  "boolean()"

  iex> to_spec_string!({:avro_primitive_type, "bytes", []}, "my_prefix")
  "binary()"

  iex> to_spec_string!({:avro_primitive_type, "double", []}, "my_prefix")
  "float()"

  iex> to_spec_string!({:avro_primitive_type, "float", []}, "my_prefix")
  "float()"

  iex> to_spec_string!({:avro_primitive_type, "int", []}, "my_prefix")
  "integer()"

  iex> to_spec_string!({:avro_primitive_type, "long", []}, "my_prefix")
  "integer()"

  iex> to_spec_string!({:avro_primitive_type, "null", []}, "my_prefix")
  "nil"

  iex> to_spec_string!({:avro_primitive_type, "string", []}, "my_prefix")
  "String.t()"

  An unknown type will raise an ArgumentError:

  iex> to_spec_string!({:avro_primitive_type, "non-existent-type", []}, "my_prefix")
  ** (ArgumentError) unsupported type: "non-existent-type"

  ### Logical types

  iex> to_spec_string!({:avro_primitive_type, "bytes", [{"logicalType", "decimal"}, {"precision", 4}, {"scale", 2}]}, "my_prefix")
  "Decimal.t()"

  iex> to_spec_string!({:avro_primitive_type, "string", [{"logicalType", "uuid"}]}, "my_prefix")
  "String.t()"

  iex> to_spec_string!({:avro_primitive_type, "int", [{"logicalType", "date"}]}, "my_prefix")
  "Date.t()"

  iex> to_spec_string!({:avro_primitive_type, "int", [{"logicalType", "time-millis"}]}, "my_prefix")
  "Time.t()"

  iex> to_spec_string!({:avro_primitive_type, "long", [{"logicalType", "time-micros"}]}, "my_prefix")
  "Time.t()"

  iex> to_spec_string!({:avro_primitive_type, "long", [{"logicalType", "timestamp-millis"}]}, "my_prefix")
  "DateTime.t()"

  iex> to_spec_string!({:avro_primitive_type, "long", [{"logicalType", "timestamp-micros"}]}, "my_prefix")
  "DateTime.t()"

  iex> to_spec_string!({:avro_primitive_type, "long", [{"logicalType", "local-timestamp-millis"}]}, "my_prefix")
  "NaiveDateTime.t()"

  iex> to_spec_string!({:avro_primitive_type, "long", [{"logicalType", "local-timestamp-micros"}]}, "my_prefix")
  "NaiveDateTime.t()"

  An unknown logical type or a non-existent {primitive, logical} type combination will raise an ArgumentError:

  iex> to_spec_string!({:avro_primitive_type, "int", [{"logicalType", "unsupported-logical-type"}]}, "my_prefix")
  ** (ArgumentError) unsupported type: {"int", "unsupported-logical-type"}

  iex> to_spec_string!({:avro_primitive_type, "string", [{"logicalType", "timestamp-millis"}]}, "my_prefix")
  ** (ArgumentError) unsupported type: {"string", "timestamp-millis"}

  ### Fixed types

  iex> to_spec_string!({:avro_fixed_type, "md5", "test", [], 16, "test.md5", []}, "my_prefix")
  "<<_::128>>"

  ### Array types

  iex> to_spec_string!({:avro_array_type, {:avro_primitive_type, "string", []}, []}, "my_prefix")
  "[String.t()]"

  iex> to_spec_string!({:avro_array_type, {:avro_primitive_type, "int", [{"logicalType", "date"}]}, []}, "my_prefix")
  "[Date.t()]"

  Primitive types error logic still applies:

  iex> to_spec_string!({:avro_array_type, {:avro_primitive_type, "string", [{"logicalType", "date"}]}, []}, "my_prefix")
  ** (ArgumentError) unsupported type: {"string", "date"}

  ### Map types

  iex> to_spec_string!({:avro_map_type, {:avro_primitive_type, "int", []}, []}, "my_prefix")
  "%{String.t() => integer()}"

  iex> to_spec_string!({:avro_map_type, {:avro_primitive_type, "int", [{"logicalType", "time-millis"}]}, []}, "my_prefix")
  "%{String.t() => Time.t()}"

  Primitive types error logic still applies:

  iex> to_spec_string!({:avro_map_type, {:avro_primitive_type, "string", [{"logicalType", "date"}]}, []}, "my_prefix")
  ** (ArgumentError) unsupported type: {"string", "date"}

  ### Union types

  iex> to_spec_string!({:avro_union_type,
  ...>  {2,
  ...>   {1, {:avro_primitive_type, "string", []},
  ...>    {0, {:avro_primitive_type, "null", []}, nil, nil}, nil}},
  ...>  {2, {"string", {1, true}, {"null", {0, true}, nil, nil}, nil}}}, "my_prefix")
  "nil | String.t()"

  ### References

  iex> to_spec_string!("test.Type", "my_prefix")
  "MyPrefix.Test.Type.t()"
  """
  # TODO should we rename this to something like to_typespec ?
  @spec to_spec_string!(:avro.type_or_name(), module_prefix :: String.t()) ::
          String.t() | no_return()
  def to_spec_string!({:avro_primitive_type, name, custom}, _module_prefix) do
    custom
    |> List.keyfind("logicalType", 0)
    |> case do
      nil ->
        get_spec_string(@primitive_type_spec_strings, name)

      {"logicalType", logical_type} ->
        get_spec_string(@logical_types_spec_strings, {name, logical_type})
    end
  end

  def to_spec_string!(
        {:avro_fixed_type, _name, _namespace, _aliases, size, _fullname, _custom},
        _module_prefix
      ) do
    "<<_::#{size * 8}>>"
  end

  def to_spec_string!({:avro_array_type, type, _custom}, module_prefix) do
    "[#{to_spec_string!(type, module_prefix)}]"
  end

  def to_spec_string!({:avro_map_type, type, _custom}, module_prefix) do
    "%{String.t() => #{to_spec_string!(type, module_prefix)}}"
  end

  def to_spec_string!({:avro_union_type, _id2type, _name2id} = union, module_prefix) do
    union
    |> :avro_union.get_types()
    |> Enum.map(&to_spec_string!(&1, module_prefix))
    |> Enum.join(" | ")
  end

  # TODO should I delete this?
  def to_spec_string!(
        {:avro_record_field, _name, _doc, fullname, _default, _ordering, _aliases},
        _module_prefix
      )
      when is_binary(fullname) do
    # eg: fullname=atp.players.Trainer
    "#{camelize(fullname)}.t(), enforce: true"
  end

  def to_spec_string!(reference, module_prefix) when is_binary(reference) do
    "#{camelize(module_prefix)}.#{camelize(reference)}.t()"
  end

  def to_spec_string!(type, _base_path) do
    raise ArgumentError, message: "unsupported avro type: #{inspect(type)}"
  end

  @spec get_spec_string(map, String.t()) :: String.t() | no_return()
  defp get_spec_string(types_map, type) do
    case Map.get(types_map, type) do
      nil -> raise ArgumentError, message: "unsupported type: #{inspect(type)}"
      type -> type
    end
  end

  @spec encode_value!(
          value_expression :: String.t(),
          :avro.type_or_name(),
          module_prefix :: String.t()
        ) :: String.t() | no_return()
  def encode_value!(
        value_expression,
        {:avro_primitive_type, "int", [{"logicalType", "date"}]},
        _module_prefix
      ) do
    "ElixirAvro.Generator.Types.Date.encode_value!(#{value_expression})"
  end

  def encode_value!(value_expression, fullname, module_prefix) when is_binary(fullname) do
    "ElixirAvro.Generator.Types.Record.encode_value!(#{value_expression}, :\"#{module_prefix}.#{camelize(fullname)}\")"
  end

  def encode_value!(value_expression, _type, _module_prefix) do
    value_expression
  end

  @spec encode_value(any(), :avro.type_or_name()) :: {:ok, any()} | {:error, any()}
  def encode_value(value, _) do
    {:ok, value}
  end

  @spec decode_value(any(), :avro.type_or_name()) :: {:ok, any()} | {:error, any()}
  def decode_value(_, _) do
  end

  # this is duplicated, put it in utils or something similar
  defp camelize(fullname) do
    fullname
    |> String.split(".")
    |> Enum.map(&Macro.camelize/1)
    |> Enum.join(".")
  end
end
