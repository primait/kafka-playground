defmodule ElixirAvro.AvroraDiscovery.EncodingPrimitiveTypesTest do
  use ExUnit.Case

  describe "boolean" do
    test "valid" do
      assert {:ok, _} =
               ElixirAvro.AvroraClient.encode(%{"active" => true},
                 schema_name: "types.primitive.Boolean"
               )
    end

    test "invalid" do
      assert ElixirAvro.AvroraClient.encode(%{"active" => "true"},
               schema_name: "types.primitive.Boolean"
             ) == {
               :error,
               %ErlangError{
                 original:
                   {:"$avro_encode_error",
                    {:badmatch,
                     {:error, {:type_mismatch, {:avro_primitive_type, "boolean", []}, "true"}}},
                    [record: "types.primitive.Boolean", field: "active"]},
                 reason: nil
               }
             }
    end

    test "encode/decode" do
      message = %{"active" => true}
      {:ok, binary} =
        ElixirAvro.AvroraClient.encode_plain(message,
          schema_name: "types.primitive.Boolean"
        )

      assert {:ok, message} == ElixirAvro.AvroraClient.decode_plain(binary, schema_name: "types.primitive.Boolean")
    end
  end
end
