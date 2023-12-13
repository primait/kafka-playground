defmodule ElixirBrod.Avro.SchemaParser.MessageEnum do
  @moduledoc """
  This module is called MessageEnum only to avoid conflicts with the
  standard library's Enum protocol, and in fact exposes a struct
  representing the metadata to implement an enum module.
  """

  import ElixirBrod.Avro.ModuleWriter.Conventions

  @type t :: %__MODULE__{
          has_default?: boolean(),
          default: nil | atom(),
          name: String.t(),
          namespace: String.t(),
          path: String.t(),
          symbols: [atom()]
        }

  defstruct [:has_default?, :default, :name, :namespace, :path, :symbols]

  @spec from_definition(map, Path.t()) :: {:ok, t} | {:error, :invalid_definition}
  def from_definition(
        %{
          "name" => name,
          "namespace" => namespace,
          "symbols" => symbols
        } = definition,
        base_path
      ) do
    default =
      case Map.get(definition, "default") do
        nil ->
          nil

        default ->
          parse_symbol(default)
      end

    {:ok,
     %__MODULE__{
       has_default?: Map.has_key?(definition, "default"),
       default: default,
       name: name,
       namespace: namespace,
       path: generate_path!(base_path, name, namespace),
       symbols: parse_symbols([Map.get(definition, "default") | symbols])
     }}
  end

  def from_definition(_, _), do: {:error, :invalid_definition}

  @spec parse_symbols([String.t()]) :: [atom()]
  defp parse_symbols(symbols),
    do:
      symbols
      |> Enum.reject(&is_nil/1)
      |> Enum.map(&parse_symbol/1)
      |> Enum.sort()
      |> Enum.uniq()

  @spec parse_symbol(String.t()) :: atom()
  defp parse_symbol(symbol),
    do:
      symbol
      |> then(fn symbol -> Regex.replace(~r/\s/, symbol, "_") end)
      |> Macro.underscore()
      |> String.replace("__", "_")
      |> String.trim("_")
      |> String.to_atom()
end
