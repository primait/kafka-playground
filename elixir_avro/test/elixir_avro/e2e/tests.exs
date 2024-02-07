defmodule ElixirAvro.E2E.Tests do
  use ExUnit.Case

  defmodule AvroraClient do
    use Avrora.Client,
      schemas_path: Path.join(__DIR__, "schemas")
  end

  def test1() do
    {:ok, _pid} = AvroraClient.start_link()

    all_types_example = %MyApp.AvroGenerated.AllTypesExample{
      null_field: nil,
      boolean_field: true,
      int_field: 42,
      long_field: 1_234_567_890,
      float_field: 3.14,
      double_field: 2.71828,
      string_field: "Hello, Avro!",
      bytes_field: <<1, 2, 3>>,
      date_field: ~D[2024-02-01],
      array_field: ["item1", "item2", "item3"],
      map_field: %{"key1" => 1, "key2" => 2, "key3" => 3},
      enum_field: MyApp.AvroGenerated.ExampleEnum.symbol1(),
      union_field: 42,
      record_field: %MyApp.AvroGenerated.ExampleRecord{
        nested_string: "Nested String",
        nested_int: 123,
        nested_enum: MyApp.AvroGenerated.NestedEnum.nested_symbol2(),
        nested_record: %MyApp.AvroGenerated.NestedRecord{
          nested_string: "Nested Record String",
          nested_enum: MyApp.AvroGenerated.NestedEnum.nested_symbol1()
        }
      }
    }

    assert {:ok, encoded} =
             all_types_example
             |> MyApp.AvroGenerated.AllTypesExample.to_avro_map()
             |> AvroraClient.encode_plain(schema_name: "AllTypesExample")

    assert {:ok,
            %{
              "array_field" => ["item1", "item2", "item3"],
              "boolean_field" => true,
              "bytes_field" => <<1, 2, 3>>,
              "date_field" => 19754,
              "double_field" => 2.71828,
              "enum_field" => "SYMBOL1",
              "float_field" => 3.140000104904175,
              "int_field" => 42,
              "long_field" => 1_234_567_890,
              "map_field" => %{"key1" => 1, "key2" => 2, "key3" => 3},
              "null_field" => nil,
              "record_field" => %{
                "nested_enum" => "NESTED_SYMBOL2",
                "nested_int" => 123,
                "nested_record" => %{
                  "nested_enum" => "NESTED_SYMBOL1",
                  "nested_string" => "Nested Record String"
                },
                "nested_string" => "Nested String"
              },
              "string_field" => "Hello, Avro!",
              "union_field" => 42
            }} == AvroraClient.decode_plain(encoded, schema_name: "AllTypesExample")
  end
end
