defmodule ElixirBrod.Avro.SchemaParser do
  @moduledoc """
  This module is a factory facade that translates the avsc definition
  string into metadata with which to create the modules.
  """

  alias ElixirBrod.Avro.SchemaParser.MessageEnum
  alias ElixirBrod.Avro.MosuleWriter.Metadata
  alias ElixirBrod.Avro.SchemaParser.Record

  @doc """
  Turn an avsc into a module metadata
  """
  @spec parse(String.t(), String.t()) :: {:ok, Metadata.t()} | {:error, :invalid_definition}
  def parse(schema, base_path) do
    schema
    |> Jason.decode!()
    |> parse_file(base_path)
  end

  @spec parse_file(definition :: map(), base_path :: Path.t()) ::
          {:ok, Metadata.t()} | {:error, :invalid_definition}
  defp parse_file(%{"type" => "enum"} = definition, base_path) do
    MessageEnum.from_definition(definition, base_path)
  end

  defp parse_file(%{"type" => "record"} = definition, base_path) do
    Record.from_definition(definition, base_path)
  end
end
