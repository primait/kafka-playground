defmodule ElixirAvro.E2ETest do
  use ExUnit.Case

  test "encode and decode" do
    target_path = Path.join(__DIR__, "e2e/generated")
    schemas_path = Path.join(__DIR__, "e2e/schemas")
    prefix = "MyApp.AvroGenerated"

    System.cmd("mix", ["elixir_avro.generate.code", target_path, schemas_path, prefix])

    generated_path = Path.join(target_path, "my_app/avro_generated")
    files = generated_path |> File.ls!() |> Enum.sort()

    assert files == [
             "all_types_example.ex",
             "example_enum.ex",
             "example_record.ex",
             "nested_enum.ex",
             "nested_record.ex"
           ]

    Enum.map(files, &Code.compile_file(Path.join(generated_path, &1)))

    # We need to do this because we need to reference modules just compiled
    Code.compile_file("test/elixir_avro/e2e/tests.exs")
    module = ElixirAvro.E2E.Tests
    module.test1()
  end
end
