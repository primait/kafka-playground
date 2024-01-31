defmodule ElixirBrod.Avro.SchemaParser.Field do
  @moduledoc false

  @callback parse_field!(definition :: map()) :: Field.t() | no_return()

  @type field_primitive_type ::
          :boolean
          | :bytes
          | :double
          | :float
          | :int
          | :long
          | :null
          | :string

  @type field_type ::
          field_primitive_type | :array | :enum | :fixed | :map | {:record, String.t()} | {:reference, String.t()} | [field_type]

  @type logical_type ::
          :"local-timestamp-micros"
          | :"local-timestamp-millis"
          | :"time-micros"
          | :"time-millis"
          | :"timestamp-micros"
          | :"timestamp-millis"
          | :date
          | :duration
          | :uuid
          | :decimal

  @type t :: %__MODULE__{
          default: nil | term(),
          description: nil | String.t(),
          fields: [t],
          items: [field_type | t],
          logical_type: nil | logical_type,
          name: String.t(),
          precision: nil | integer(),
          scale: nil | integer(),
          size: nil | integer(),
          symbols: [atom()],
          type: field_type
        }

  @type field_simple_error :: {:error, field_name :: String.t(), message :: String.t()}
  @type field_complex_error :: {:error, field_name :: String.t(), [field_error]}
  @type field_error :: field_simple_error | field_complex_error

  @primitive_types [
    "boolean",
    "bytes",
    "double",
    "float",
    "int",
    "long",
    "null",
    "string"
  ]

  defstruct [
    :type,
    :name,
    logical_type: nil,
    precision: nil,
    scale: nil,
    size: nil,
    bytes: <<>>,
    description: nil,
    symbols: [],
    items: [],
    has_default?: false,
    default: nil,
    fields: []
  ]

  @spec parse_field!(map) :: Field.t() | no_return()
  def parse_field!(map) do
    case parse_field(map) do
      {:ok, res} -> res
      {:error, error} -> raise error
      {:error, field, error} -> raise "Not able to parse field #{field}. #{error}"
    end
  end

  @spec parse_field(map) ::
          {:ok, Field.t()} | {:error, String.t(), String.t()} | {:error, String.t()}
  def parse_field(%{"type" => type, "name" => _} = definition),
    do: apply_strategy(type, definition)

  def parse_field(definition), do: {:error, "Malformed definition\n\n#{inspect(definition)}"}

  @spec logical_type_validation_map() :: map
  defp logical_type_validation_map,
    do: %{
      "local-timestamp-micros": {"long", &create_logical_type/1},
      "local-timestamp-millis": {"long", &create_logical_type/1},
      "time-micros": {"long", &create_logical_type/1},
      "time-millis": {"int", &create_logical_type/1},
      "timestamp-micros": {"long", &create_logical_type/1},
      "timestamp-millis": {"long", &create_logical_type/1},
      date: {"int", &create_logical_type/1},
      duration: {"fixed", &create_duration/1},
      uuid: {"string", &create_logical_type/1},
      decimal: {["bytes", "fixed"], &create_decimal/1}
    }

  @spec extract_default_for(String.t(), map) :: {:ok, String.t() | map()} | {:error, String.t()}
  # TODO: validate the default for every type
  defp extract_default_for("enum", %{"default" => nil, "symbols" => _}), do: nil

  defp extract_default_for("enum", %{"default" => default, "symbols" => symbols}) do
    if Enum.member?(symbols, default) do
      {:ok, String.to_atom(default)}
    else
      {:error, "The default should be a valid symbol"}
    end
  end

  defp extract_default_for(_type, definition), do: {:ok, Map.get(definition, "default", nil)}

  @spec create_logical_type(map) :: {:ok, t} | {:error, String.t(), String.t()}
  defp create_logical_type(
         %{"name" => name, "logicalType" => logical_type, "type" => type} = definition
       ) do
    case extract_default_for(type, definition) do
      {:ok, default} ->
        {:ok,
         %__MODULE__{
           type: String.to_existing_atom(type),
           logical_type: String.to_existing_atom(logical_type),
           name: name,
           default: default,
           description: Map.get(definition, :description)
         }}

      {:error, message} ->
        {:error, name, message}
    end
  end

  @spec create_duration(map) :: {:ok, t} | {:error, String.t(), String.t()}
  defp create_duration(
         %{
           "name" => name,
           "logicalType" => _,
           "type" => "fixed",
           "size" => 12
         } = definition
       ) do
    case extract_default_for("fixed", definition) do
      {:ok, default} ->
        {:ok,
         %__MODULE__{
           type: :fixed,
           logical_type: :duration,
           size: 12,
           name: name,
           default: default,
           description: Map.get(definition, :description)
         }}

      {:error, message} ->
        {:error, name, message}
    end
  end

  defp create_duration(%{"name" => name} = definition),
    do:
      {:error, name,
       "Invalid duration, please refer to Avro documentation\n\n#{inspect(definition)}"}

  @spec create_decimal(map) :: {:ok, t} | {:error, String.t(), String.t()}
  defp create_decimal(
         %{
           "name" => name,
           "logicalType" => _,
           "type" => type,
           "precision" => precision,
           "scale" => scale
         } = definition
       )
       when is_integer(precision) and is_integer(scale) and scale >= 0 and precision > 0 and
              type in ["bytes", "fixed"] do
    case extract_default_for(type, definition) do
      {:ok, default} ->
        {:ok,
         %__MODULE__{
           default: default,
           name: name,
           logical_type: :decimal,
           type: String.to_existing_atom(type),
           precision: precision,
           scale: scale,
           description: Map.get(definition, :description)
         }}

      {:error, message} ->
        {:error, name, message}
    end
  end

  defp create_decimal(
         %{
           "name" => _,
           "logicalType" => _,
           "type" => type,
           "precision" => precision
         } = definition
       )
       when is_integer(precision) and precision > 0 and type in ["bytes", "fixed"],
       do:
         definition
         |> Map.put_new("scale", 0)
         |> create_decimal()

  defp create_decimal(%{"name" => name} = definition),
    do:
      {:error, name,
       "Invalid decimal, please refer to Avro documentation\n\n#{inspect(definition)}"}

  @spec apply_strategy(type :: String.t(), definition :: map) :: {:ok, t} | field_error
  defp apply_strategy(types, %{"name" => name} = definition) when is_list(types) do
    fields =
      Enum.map(types, fn type ->
        apply_strategy(type, Map.put(%{definition | "type" => type}, "definiton", nil))
      end)

    case Enum.group_by(fields, &elem(&1, 0)) do
      %{error: _} ->
        {:error, name, "Malformed union type definition\n\n#{inspect(types)}"}

      %{ok: fields} ->
        case extract_default_for(types, definition) do
          {:ok, default} ->
            Enum.reduce(
              fields,
              {:ok,
               %__MODULE__{
                 default: default,
                 name: name,
                 description: Map.get(definition, :description),
                 type: []
               }},
              fn {:ok, field}, {:ok, %__MODULE__{type: type} = result} ->
                {:ok,
                 %{
                   result
                   | type:
                       ([type] ++ [field.type])
                       |> List.flatten()
                       |> Enum.uniq()
                 }}
              end
            )

          {:error, message} ->
            {:error, name, message}
        end
    end
  end

  defp apply_strategy(type, %{"name" => name, "logicalType" => logical_type} = definition) do
    logical_type = String.to_existing_atom(logical_type)

    case Map.get(logical_type_validation_map(), logical_type, false) do
      {^type, factory} ->
        factory.(definition)

      {types, factory} when is_list(types) ->
        if type in types do
          factory.(definition)
        else
          {:error, name,
           "Invalid logicalType, please refer to Avro documentation\n\n#{inspect(definition)}"}
        end

      false ->
        {:error, name,
         "Invalid logicalType, please refer to Avro documentation\n\n#{inspect(definition)}"}
    end
  rescue
    _ in ArgumentError ->
      {:error, name, "Unsupported logicalType: #{logical_type}"}
  end

  defp apply_strategy(type, %{"name" => name} = definition)
       when type in @primitive_types do
    case extract_default_for(type, definition) do
      {:ok, default} ->
        {:ok,
         %__MODULE__{
           default: default,
           type: String.to_existing_atom(type),
           name: name,
           description: Map.get(definition, :description)
         }}

      {:error, message} ->
        {:error, name, message}
    end
  end

  defp apply_strategy("fixed", %{"name" => name, "size" => size} = definition)
       when is_integer(size) and size > 0 do
    case extract_default_for("fixed", definition) do
      {:ok, default} ->
        {:ok,
         %__MODULE__{
           name: name,
           default: default,
           type: :fixed,
           size: size
         }}

      {:error, message} ->
        {:error, name, message}
    end
  end

  defp apply_strategy(type, %{"name" => name, "items" => items} = definition)
       when type in ["array", "map"] do
    case parse_item(items) do
      {:error, _, _} = error ->
        {:error, name, error}

      {:error, message} ->
        {:error, name, message}

      {:ok, field} ->
        case extract_default_for(type, definition) do
          {:ok, default} ->
            {:ok,
             %__MODULE__{
               name: name,
               default: default,
               type: String.to_existing_atom(type),
               items: field
             }}

          {:error, message} ->
            {:error, name, message}
        end
    end
  end

  defp apply_strategy("enum", %{"name" => name, "symbols" => symbols} = definition) do
    case extract_default_for("enum", definition) do
      {:ok, default} ->
        symbols =
          symbols
          |> Enum.map(&String.to_atom/1)
          |> Enum.uniq()

        {:ok,
         %__MODULE__{
           name: name,
           default: default,
           type: :enum,
           symbols: symbols
         }}

      {:error, message} ->
        {:error, name, message}
    end
  end

  defp apply_strategy("record", %{"name" => name, "fields" => fields, "namespace" => namespace} = definition) do
    case extract_default_for("record", definition) do
      {:ok, default} ->
        fields =
          fields
          |> Enum.map(&parse_field/1)
          |> Enum.uniq()

        case Enum.group_by(fields, &elem(&1, 0)) do
          %{error: _} ->
            {:error, name, "Malformed record type definition\n\n#{inspect(definition)}"}

          %{ok: fields} ->
            fields = Enum.map(fields, &elem(&1, 1))

            {:ok,
             %__MODULE__{
               name: name,
               default: default,
               type: {:record, namespace},
               fields: fields
             }}
        end

      {:error, message} ->
        {:error, name, message}
    end
  end

  defp apply_strategy(type, %{"name" => name}) do
    {:ok,
     %__MODULE__{
       name: name,
       type: {:reference, type}
     }}
  end

  @spec parse_item(map) :: {:ok, atom} | {:ok, t} | {:error, message :: String.t()}
  defp parse_item(item) when item in @primitive_types,
    do: {:ok, String.to_existing_atom(item)}

  defp parse_item(items) when is_list(items) do
    items
    |> Enum.map(fn item -> parse_item(item) end)
    |> Enum.group_by(&elem(&1, 0))
    |> case do
      %{error: _} ->
        {:error, "Malformed items definition: \"#{inspect(items)}\""}

      %{ok: items} ->
        {:ok, Enum.map(items, &elem(&1, 1))}
    end
  end

  defp parse_item(%{"name" => _, "type" => type} = item),
    do: apply_strategy(type, item)

  defp parse_item(item),
    do: {:error, "Malformed items definition: #{inspect(item)}"}
end
