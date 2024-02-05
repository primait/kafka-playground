defmodule Mix.Tasks.ElixirAvro.Generate.CodeTest do
  use ExUnit.Case

  # we could actually mock and do a unit test
  test "mix generation task" do
    target_path = Path.join(__DIR__, "/generated")
    schemas_path = Path.join(__DIR__, "/schemas")
    # understand if this is a good API or should we split the target_path in two parts?
    module_prefix = "ElixirAvro.Generated"

    System.cmd("mix", ["elixir_avro.generate.code", target_path, schemas_path, module_prefix])

    ["PlayerRegistered.ex", "Trainer.ex"] =
      File.ls!(Path.join(target_path, "ElixirAvro/Generated/Atp/Players")) |> Enum.sort()

    # TODO here we could test also for the content
  end
end
