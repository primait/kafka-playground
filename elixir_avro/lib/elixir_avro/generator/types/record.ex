defmodule ElixirAvro.Generator.Types.Record do
  def encode_value!(value, module_name) do
    case value do
      %module_name{} ->
        module_name.to_avro_map(value)

      _ ->
        raise "Invalid value for record #{module_name}"
    end
  end
end
