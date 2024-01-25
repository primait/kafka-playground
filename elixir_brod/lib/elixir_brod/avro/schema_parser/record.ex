defmodule ElixirBrod.Avro.SchemaParser.Record do
  @moduledoc """
  This module exposes a struct that contains the
  metadata to create a record-type module.
  """

  alias ElixirBrod.Avro.SchemaParser.Field

  @type t :: %__MODULE__{
          name: String.t(),
          description: nil | String.t(),
          namespace: String.t(),
          base_path: String.t(),
          fields: [Field.t()]
        }

  defstruct [:name, :namespace, :base_path, :fields, :description]

  @spec from_definition(map(), Path.t()) :: {:ok, t} | {:error, :invalid_definition}
  def from_definition(
        %{
          "name" => name,
          "namespace" => namespace,
          "fields" => fields
        } = definition,
        base_path
      ) do
    {:ok,
     %__MODULE__{
       name: name,
       namespace: namespace,
       description: Map.get(definition, "description"),
       base_path: base_path,
       fields: parse_fields!(fields)
     }}
  end

  def from_definition(_, _), do: {:error, :invalid_definition}

  @spec parse_fields!([map()]) :: [Field.t()] | no_return()
  defp parse_fields!(field_definitions),
    do: Enum.map(field_definitions, &Field.parse_field!/1)
end
