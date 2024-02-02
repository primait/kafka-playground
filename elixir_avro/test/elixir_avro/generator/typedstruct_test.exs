defmodule ElixirAvro.Generator.TypedstructTest do
  use ExUnit.Case

  alias ElixirAvro.Generator.Typedstruct

  describe "primitives" do
    test "boolean" do
      assert "boolean(), enforce: true" == Typedstruct.spec_for(erlavro_record_field(:boolean))
    end

    test "int/long" do
      assert "integer(), enforce: true" == Typedstruct.spec_for(erlavro_record_field(:int))
      assert "integer(), enforce: true" == Typedstruct.spec_for(erlavro_record_field(:long))
    end

    test "float/double" do
      assert "float(), enforce: true" == Typedstruct.spec_for(erlavro_record_field(:float))
      assert "float(), enforce: true" == Typedstruct.spec_for(erlavro_record_field(:double))
    end

    test "bytes/string" do
      assert "String.t(), enforce: true" == Typedstruct.spec_for(erlavro_record_field(:bytes))
      assert "String.t(), enforce: true" == Typedstruct.spec_for(erlavro_record_field(:string))
    end
  end

  describe "logical types" do
    test "uuid" do
      assert "String.t(), enforce: true" == Typedstruct.spec_for(erlavro_record_field(:uuid))
    end

    test "date" do
      assert "Date.t(), enforce: true" == Typedstruct.spec_for(erlavro_record_field(:date))
    end
  end

  describe "union types" do
    test "null|string" do
      assert "String.t()" == Typedstruct.spec_for(erlavro_record_field(:null_or_string))
    end
  end

  defp field_definition(:date) do
    ~s/{"name":"field_name","type":{"type":"int","logicalType":"date"}}/
  end

  defp field_definition(:uuid) do
    ~s/{"name":"field_name","type":{"type":"string","logicalType":"uuid"}}/
  end

  defp field_definition(:null_or_string) do
    ~s/{"name":"field_name","type":["null","string"]}/
  end

  defp field_definition(type) do
    ~s/{"name":"field_name","type":"#{to_string(type)}"}/
  end

  defp erlavro_record_field(type) when is_atom(type) do
    erlavro_record_field(field_definition(type))
  end

  defp erlavro_record_field(field_definition) do
    {:avro_record_type, "root", "", "", [], [field], _, _} =
      :avro_json_decoder.decode_schema(
        ~s/{"name":"root","type":"record","fields":[#{field_definition}]}/
      )

    field
  end
end
