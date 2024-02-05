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

  def to_typedstruct_spec!(type, base_path) do
    to_spec_string!(type, base_path) <> ", enforce: #{enforce?(type)}"
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

  iex> to_spec_string!({:avro_primitive_type, "boolean", []}, "base_path")
  "boolean()"

  iex> to_spec_string!({:avro_primitive_type, "bytes", []}, "base_path")
  "binary()"

  iex> to_spec_string!({:avro_primitive_type, "double", []}, "base_path")
  "float()"

  iex> to_spec_string!({:avro_primitive_type, "float", []}, "base_path")
  "float()"

  iex> to_spec_string!({:avro_primitive_type, "int", []}, "base_path")
  "integer()"

  iex> to_spec_string!({:avro_primitive_type, "long", []}, "base_path")
  "integer()"

  iex> to_spec_string!({:avro_primitive_type, "null", []}, "base_path")
  "nil"

  iex> to_spec_string!({:avro_primitive_type, "string", []}, "base_path")
  "String.t()"

  An unknown type will raise an ArgumentError:

  iex> to_spec_string!({:avro_primitive_type, "non-existent-type", []}, "base_path")
  ** (ArgumentError) unsupported type: "non-existent-type"

  ### Logical types

  iex> to_spec_string!({:avro_primitive_type, "bytes", [{"logicalType", "decimal"}, {"precision", 4}, {"scale", 2}]}, "base_path")
  "Decimal.t()"

  iex> to_spec_string!({:avro_primitive_type, "string", [{"logicalType", "uuid"}]}, "base_path")
  "String.t()"

  iex> to_spec_string!({:avro_primitive_type, "int", [{"logicalType", "date"}]}, "base_path")
  "Date.t()"

  iex> to_spec_string!({:avro_primitive_type, "int", [{"logicalType", "time-millis"}]}, "base_path")
  "Time.t()"

  iex> to_spec_string!({:avro_primitive_type, "long", [{"logicalType", "time-micros"}]}, "base_path")
  "Time.t()"

  iex> to_spec_string!({:avro_primitive_type, "long", [{"logicalType", "timestamp-millis"}]}, "base_path")
  "DateTime.t()"

  iex> to_spec_string!({:avro_primitive_type, "long", [{"logicalType", "timestamp-micros"}]}, "base_path")
  "DateTime.t()"

  iex> to_spec_string!({:avro_primitive_type, "long", [{"logicalType", "local-timestamp-millis"}]}, "base_path")
  "NaiveDateTime.t()"

  iex> to_spec_string!({:avro_primitive_type, "long", [{"logicalType", "local-timestamp-micros"}]}, "base_path")
  "NaiveDateTime.t()"

  An unknown logical type or a non-existent {primitive, logical} type combination will raise an ArgumentError:

  iex> to_spec_string!({:avro_primitive_type, "int", [{"logicalType", "unsupported-logical-type"}]}, "base_path")
  ** (ArgumentError) unsupported type: {"int", "unsupported-logical-type"}

  iex> to_spec_string!({:avro_primitive_type, "string", [{"logicalType", "timestamp-millis"}]}, "base_path")
  ** (ArgumentError) unsupported type: {"string", "timestamp-millis"}

  ### Fixed types

  iex> to_spec_string!({:avro_fixed_type, "md5", "test", [], 16, "test.md5", []}, "base_path")
  "<<_::128>>"

  ### Array types

  iex> to_spec_string!({:avro_array_type, {:avro_primitive_type, "string", []}, []}, "base_path")
  "[String.t()]"

  iex> to_spec_string!({:avro_array_type, {:avro_primitive_type, "int", [{"logicalType", "date"}]}, []}, "base_path")
  "[Date.t()]"

  Primitive types error logic still applies:

  iex> to_spec_string!({:avro_array_type, {:avro_primitive_type, "string", [{"logicalType", "date"}]}, []}, "base_path")
  ** (ArgumentError) unsupported type: {"string", "date"}

  ### Map types

  iex> to_spec_string!({:avro_map_type, {:avro_primitive_type, "int", []}, []}, "base_path")
  "%{String.t() => integer()}"

  iex> to_spec_string!({:avro_map_type, {:avro_primitive_type, "int", [{"logicalType", "time-millis"}]}, []}, "base_path")
  "%{String.t() => Time.t()}"

  Primitive types error logic still applies:

  iex> to_spec_string!({:avro_map_type, {:avro_primitive_type, "string", [{"logicalType", "date"}]}, []}, "base_path")
  ** (ArgumentError) unsupported type: {"string", "date"}

  ### Union types

  iex> to_spec_string!({:avro_union_type,
  ...>  {2,
  ...>   {1, {:avro_primitive_type, "string", []},
  ...>    {0, {:avro_primitive_type, "null", []}, nil, nil}, nil}},
  ...>  {2, {"string", {1, true}, {"null", {0, true}, nil, nil}, nil}}}, "base_path")
  "nil | String.t()"

  ### References

  iex> to_spec_string!("test.Type", "base_path")
  "Test.Type.t()"
  """
  # TODO should we rename this to something like to_typespec ?
  @spec to_spec_string!(:avro.type_or_name(), Path.t()) :: String.t() | no_return()
  def to_spec_string!({:avro_primitive_type, name, custom}, _base_path) do
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
        _base_path
      ) do
    "<<_::#{size * 8}>>"
  end

  def to_spec_string!({:avro_array_type, type, _custom}, base_path) do
    "[#{to_spec_string!(type, base_path)}]"
  end

  def to_spec_string!({:avro_map_type, type, _custom}, base_path) do
    "%{String.t() => #{to_spec_string!(type, base_path)}}"
  end

  def to_spec_string!({:avro_union_type, id2type, _name2id}, base_path) do
    # TODO use :avro_union.get_types instead
    id2type
    |> :gb_trees.to_list()
    |> Enum.map(&elem(&1, 1))
    |> Enum.map(&to_spec_string!(&1, base_path))
    |> Enum.join(" | ")
  end

  def to_spec_string!(
        {:avro_record_field, _name, _doc, fullname, _default, _ordering, _aliases},
        _base_path
      )
      when is_binary(fullname) do
    # eg: fullname=atp.players.Trainer
    "#{camelize(fullname)}.t(), enforce: true"
  end

  def to_spec_string!(reference, _base_path) when is_binary(reference) do
    "#{camelize(reference)}.t()"
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

  @spec encode_value!(String.t(), :avro.type_or_name()) :: String.t() | no_return()
  def encode_value!(value_expression, {:avro_primitive_type, "int", [{"logicalType", "date"}]}) do
    "ElixirAvro.Generator.Types.Date.encode_value!(#{value_expression})"
  end

  def encode_value!(value_expression, fullname) when is_binary(fullname) do
    "ElixirAvro.Generator.Types.Record.encode_value!(#{value_expression}, \"#{fullname}\")"
  end

  def encode_value!(value_expression, _) do
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
    |> Enum.map(&:string.titlecase/1)
    |> Enum.join(".")
  end
end
