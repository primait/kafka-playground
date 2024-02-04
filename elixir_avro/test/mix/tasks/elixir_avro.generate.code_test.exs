defmodule Mix.Tasks.ElixirAvro.Generate.CodeTest do
  use ExUnit.Case

  # we could actually mock and do a unit test
  test "mix generation task" do
    target_path = Path.join(__DIR__, "/generated")
    schemas_path = Path.join(__DIR__, "/schemas")
    System.cmd("mix", ["elixir_avro.generate.code", target_path, schemas_path])

    ["PlayerRegistered.ex", "Trainer.ex"] =
      File.ls!(Path.join(target_path, "Atp/Players")) |> Enum.sort()

    # TODO here we could test also for the content
  end
end
