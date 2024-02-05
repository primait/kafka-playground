defmodule ElixirAvro.Generator.Types do
  @spec to_spec_string!(:avro.type_or_name(), Path.t()) :: String.t() | no_return()
  def to_spec_string!(_, _) do
    "String.t()"
  end

  @spec encode_value(any(), :avro.type_or_name()) :: any() | no_return()
  def encode_value!(value, _) do
    value
  end

  @spec encode_value(any(), :avro.type_or_name()) :: {:ok, any()} | {:error, any()}
  def encode_value(value, _) do
    {:ok, value}
  end

  @spec decode_value(any(), :avro.type_or_name()) :: {:ok, any()} | {:error, any()}
  def decode_value(_, _) do
  end
end
