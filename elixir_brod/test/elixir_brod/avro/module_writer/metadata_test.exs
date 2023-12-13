defmodule ElixirBrod.Avro.ModuleWriter.MetadataTest do

  use ExUnit.Case
  
  alias ElixirBrod.Avro.ModuleWriter.Metadata
  alias ElixirBrod.Avro.SchemaParser.Field
  alias ElixirBrod.Avro.SchemaParser.MessageEnum
  alias ElixirBrod.Avro.SchemaParser.Record

  test "it should generate an Enum module" do
    enum = %MessageEnum{
      namespace: "test_suite",
      name: "TestEnum",
      path: "lib/ElixirBrod/test_suite/TestEnum.ex",
      symbols: [:test1, :test2]
    }

    module_content = Metadata.to_string(enum)
    
    assert module_content =~ "defmodule ElixirBrod.TestSuite.TestEnum do"
    assert module_content =~ "@type t :: :test1 | :test2"
    assert module_content =~ "@values [:test1, :test2]"
    assert module_content =~ "def valid?"

    assert {{:module, ElixirBrod.TestSuite.TestEnum, _, {:create, 1}}, []} = Code.eval_string(module_content)
  end

  test "it should generate a Record module" do
    record = %Record{
      namespace: "test_suite",
      name: "TestRecord",
      path: "lib/ElixirBrod/test_suite/TestRecord.ex",
      fields: [
        %Field{
          name: "a_field",
          description: "a description",
          type: :string
        },
        %Field{
          name: "another_field",
          description: "another description",
          type: :double
        },
        %Field{
          name: "a_boolean",
          description: "a true description",
          type: :boolean
        },
        %Field{
          name: "a_union",
          type: [:null, :string]
        },
        %Field{
          name: "an array field",
          type: :array, 
          items: [:null, :float]
        }, 
        %Field{
          name: "a map field",
          type: :map,
          items: [:null, :int]
        },
        %Field{
          name: "a fixed file",
          type: :fixed,
          size: 12
        }
      ]
    }

    module_content = Metadata.to_string(record)

    assert module_content =~ "defmodule ElixirBrod.TestSuite.TestRecord do"
    assert module_content =~ "@type t :: %__MODULE__{"
    assert module_content =~ "a_field: String.t(),"
    assert module_content =~ "another_field: float(),"
    assert module_content =~ "a_boolean: boolean(),"
    assert module_content =~ "a_union: nil | String.t(),"
    assert module_content =~ "an_array_field: [nil | float()],"    
    assert module_content =~ "a_map_field: %{String.t() => nil | integer()},"
    assert module_content =~ "a_fixed_file: <<_::96>>"

    assert {{:module, ElixirBrod.TestSuite.TestRecord, _, _}, []} = Code.eval_string(module_content)
  end

  test "every logical type should be associated to a type" do
    record = %Record{
      namespace: "test_suite",
      name: "TestRecordWithLogicalType",
      path: "lib/ElixirBrod/test_suite/TestRecordWithLogicalType.ex",
      fields: [
        %Field{
          name: "a_decimal",
          description: "one of two types of decimal definition",
          type: :bytes,
          precision: 4,
          scale: 2,
          logical_type: :decimal
        },
        %Field{
          name: "another_decimal",
          description: "the other way to define a decimal",
          type: :fixed,
          precision: 3,
          size: 3,
          logical_type: :decimal
        },
        %Field{
          name: "a_date",
          type: :integer,
          logical_type: :"timestamp-millis"
        },
      ] 
    }

    module_content = Metadata.to_string(record)

    assert module_content =~ "defmodule ElixirBrod.TestSuite.TestRecordWithLogicalType do"
    assert module_content =~ "@type t :: %__MODULE__{"
    assert module_content =~ "a_decimal: Decimal.t(),"
    assert module_content =~ "another_decimal: Decimal.t(),"
    assert module_content =~ "a_date: DateTime.t()"

    assert {{:module, ElixirBrod.TestSuite.TestRecordWithLogicalType, _, _}, []} = Code.eval_string(module_content)
  end

  test "it should generate a valid struct" do
    record = %Record{
      namespace: "test_suite",
      name: "TestValidRecord",
      path: "lib/ElixirBrod/test_suite/TestValidRecord.ex",
      fields: [
        %Field{
          name: "a_field",
          description: "a description",
          type: :string
        },
        %Field{
          name: "another_field",
          description: "another description",
          type: :double
        },
        %Field{
          name: "a_boolean",
          description: "a true description",
          type: :boolean
        }
      ]}
    
    module_content = Metadata.to_string(record)
    |> Code.format_string!()
    |> to_string()
    |> tap(& File.write!("/tmp/module.ex", &1))

    assert {{:module, ElixirBrod.TestSuite.TestValidRecord, _, _}, []} = Code.eval_string(module_content)

    assert {:ok, _} = ElixirBrod.TestSuite.TestValidRecord.create(
                        %{
                          a_field: "a string",
                          another_field: 22.1,
                          a_boolean: true,
                          a_date: ~U[1970-01-01 23:59:00Z],
                          a_union: nil,
                          an_array_field: [nil, 0.1]
                        })

    
    assert {:error, _} = ElixirBrod.TestSuite.TestValidRecord.create(
                        %{
                          a_field: "a string",
                          another_field: "dunno",
                          a_boolean: true,
                          a_date: ~U[1970-01-01 23:59:00Z],
                        })
  end
end
