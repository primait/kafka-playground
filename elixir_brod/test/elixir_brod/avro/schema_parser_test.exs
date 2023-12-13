defmodule ElixirBrod.Avro.SchmemaParserTest do
  use ExUnit.Case, async: true

  alias ElixirBrod.Avro.SchemaParser
  alias ElixirBrod.Avro.SchemaParser.MessageEnum
  alias ElixirBrod.Avro.SchemaParser.Record

  test "It should parse an avsc definition of an enum" do
    schema = """
    {
      "name": "RepairType",
      "namespace": "ticketing_system",
      "type": "enum",
      "default": "unknown",
      "symbols": [
        "windshield",
        "bumper",
        "body",
        "unknown"
      ]
    }
    """

    assert {:ok,
            %MessageEnum{
              name: "RepairType",
              has_default?: true,
              namespace: "ticketing_system",
              default: :unknown,
              path: "lib/elixir_brod/a_subpath/ticketing_system/repair_type.ex",
              symbols: [:body, :bumper, :unknown, :windshield]
            }} = SchemaParser.parse(schema, "a_subpath")
  end

  test "It should parse an avsc definition of a record" do
    schema = """
    {
      "name": "Requester",
      "type": "record",
      "namespace": "ticketing_system",
      "fields": [
        {
          "name": "email",
          "type": "string"
        },
        {
          "name": "name",
          "type": "string"
        },
        {
          "name": "middlename",
          "type": [
            "null",
            "string"
          ]
        },
        {
          "name": "surname",
          "type": "string"
        },
        {
          "name": "age",
          "type": "int"
        }
      ]
    }
    """

    assert {:ok,
            %Record{
              name: "Requester",
              namespace: "ticketing_system",
              path: "lib/elixir_brod/a_subpath/ticketing_system/requester.ex",
              fields: fields
            }} = SchemaParser.parse(schema, "a_subpath")

    assert Enum.count(fields) == 5
  end
end
