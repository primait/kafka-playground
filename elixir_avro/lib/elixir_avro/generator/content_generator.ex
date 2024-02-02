defmodule ElixirAvro.Generator.ContentGenerator do
  @moduledoc false

  alias ElixirAvro.Generator.Typedstruct

  def schema_content_to_modules_content(root_schema_content) do
    erlavro_schema_parsed = :avro_json_decoder.decode_schema(root_schema_content)

    []
    |> Kernel.++([schema_content_to_module_content(erlavro_schema_parsed)])
    |> Kernel.++([{"Atp.Players.Trainer", ""}])
    |> Enum.into(%{})
  end

  @spec schema_content_to_module_content(erlavro_schema_parsed :: tuple) ::
          {module_name :: String.t(), module_content :: String.t()}
  def schema_content_to_module_content(erlavro_schema_parsed) do
    {module_name(erlavro_schema_parsed), module_content(erlavro_schema_parsed)}
  end

  @spec module_content(erlavro_schema_parsed :: tuple) :: String.t()
  defp module_content(erlavro_schema_parsed) do
    bindings = [
      fields_meta: parse_fields(erlavro_schema_parsed)
    ]

    eval_template!(template_path(erlavro_schema_parsed), bindings,
      locals_without_parens: [{:field, :*}]
    )
  end

  defp template_path({:avro_record_type, _name, _namespace, _doc, _, _fields, _fullname, _}) do
    Path.join(__DIR__, "templates/record.ex.eex")
  end

  defp module_name({:avro_record_type, _name, _namespace, _doc, _, _fields, fullname, _}) do
    camelize(fullname)
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
    "Date.to_iso8601(#{value_expression})"
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
