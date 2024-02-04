defmodule ElixirAvro.Generator.ContentGenerator do
  @moduledoc false

  alias ElixirAvro.Generator.Typedstruct

  def modules_content_from_schema(root_schema_content) do
    erlavro_schema_parsed = :avro_json_decoder.decode_schema(root_schema_content)

    erlavro_schema_parsed
    |> ElixirAvro.Generator.TypesCollector.collect()
    |> Enum.map(fn {_fullname, erlavro_type} -> module_content(erlavro_type) end)
    |> Enum.into(%{})
  end

  @spec module_content(erlavro_schema_parsed :: tuple) :: String.t()
  defp module_content(erlavro_schema_parsed) do
    moduledoc = module_doc(erlavro_schema_parsed)
    module_name = module_name(erlavro_schema_parsed)
    parsed_fields = parse_fields(erlavro_schema_parsed)

    bindings = [
      fields_meta: parsed_fields,
      moduledoc: moduledoc,
      module_name: module_name
    ]

    module_content =
      eval_template!(template_path(erlavro_schema_parsed), bindings,
        locals_without_parens: [{:field, :*}]
      )

    {module_name, module_content}
  end

  defp template_path({:avro_record_type, _name, _namespace, _doc, _, _fields, _fullname, _}) do
    Path.join(__DIR__, "templates/record.ex.eex")
  end

  defp module_name({:avro_record_type, _name, _namespace, _doc, _, _fields, fullname, _}) do
    camelize(fullname)
  end

  # TODO check if we have something already done in erlavro
  defp module_doc({:avro_record_type, _name, _namespace, doc, _, _fields, _fullname, _}) do
    doc
  end

  # Evaluate the template file at `path` using the given `bindings`, then formats
  # it using the Elixir's code formatter and adds a trailing new line.
  # The `opts` are passed to `Code.format_string!/2`.
  @spec eval_template!(String.t(), Keyword.t(), Keyword.t()) :: String.t()
  defp eval_template!(path, bindings, opts) do
    opts = Keyword.merge([line_length: 120], opts)

    path
    |> EEx.eval_file(bindings)
    |> Code.format_string!(opts)
    |> to_string()
    |> Kernel.<>("\n")
  end

  defp parse_fields({_type, _name, _namespace, _doc, _, fields, _fullname, _}) do
    Enum.map(fields, &parse_field/1)
  end

  defp parse_field(
         {:avro_record_field, name, doc, type, :undefined, :ascending, _aliases} = field
       ) do
    %{
      doc: doc,
      name: name,
      typedstruct_spec: Typedstruct.spec_for(field),
      to_avro_map_value: to_avro_map_value(type, "r.#{name}")
    }
  end

  defp to_avro_map_value({:avro_primitive_type, _primitive_type, []}, value_expression) do
    value_expression
  end

  defp to_avro_map_value(
         {:avro_primitive_type, "int", [{"logicalType", "date"}]},
         value_expression
       ) do
    # TODO evaluate if this could actually be a real elixir function
    "Date.diff(#{value_expression}, ~D[1970-01-01])"
  end

  defp to_avro_map_value(
         {:avro_primitive_type, "string", [{"logicalType", "uuid"}]},
         value_expression
       ) do
    value_expression
  end

  defp to_avro_map_value({:avro_union_type, _, _} = union_type, value_expression) do
    _types = union_type |> :avro_union.get_types()

    # this should be a case checking wrapped in a function call
    value_expression
  end

  defp to_avro_map_value(
         fullname,
         value_expression
       )
       when is_binary(fullname) do
    """
    case #{value_expression} do
      %#{camelize(fullname)}{} ->
        #{camelize(fullname)}.to_avro_map(#{value_expression})
      _ -> raise "Invalid type for #{value_expression}"
    end
    """
  end

  # can we delete this?
  defp to_avro_map_value(
         {:avro_record_type, _name, "", "", [], _fields, fullname, []},
         value_expression
       ) do
    """
    case #{value_expression} do
      %#{camelize(fullname)}{} ->
        #{camelize(fullname)}.to_avro_map(#{value_expression})
      _ -> raise "Invalid type for #{value_expression}"
    end
    """
  end

  # this is duplicated, put it in utils or something similar
  defp camelize(fullname) do
    fullname
    |> String.split(".")
    |> Enum.map(&:string.titlecase/1)
    |> Enum.join(".")
  end
end
