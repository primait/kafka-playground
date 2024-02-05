defmodule ElixirAvro.Generator.ContentGenerator do
  @moduledoc false

  # TODO This as to take also target_path because it needs to prepend the module name mapped from the avro fullname
  # with a path specific chunk given from the client application
  def modules_content_from_schema(root_schema_content, read_schema_fun) do
    root_schema_content
    |> ElixirAvro.SchemaParser.parse(read_schema_fun)
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
         {:avro_record_field, name, doc, type, :undefined, :ascending, _aliases}
       ) do
    %{
      doc: doc,
      name: name,
      erlavro_type: type
    }
  end

  # this is duplicated, put it in utils or something similar
  defp camelize(fullname) do
    fullname
    |> String.split(".")
    |> Enum.map(&:string.titlecase/1)
    |> Enum.join(".")
  end
end
