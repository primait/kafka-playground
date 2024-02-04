defmodule Mix.Tasks.ElixirAvro.Generate.Code do
  use Mix.Task

  alias ElixirAvro.Generator.ContentGenerator
  alias Mix.Shell.IO, as: ShellIO

  @impl Mix.Task
  def run([target_path, schemas_path]) do
    {:ok, _} = Application.ensure_all_started(:elixir_avro)

    File.mkdir_p!(target_path)
    File.rm_rf!(target_path)

    "#{schemas_path}/**/*.avsc"
    |> Path.wildcard()
    |> Enum.map(&File.read!/1)
    |> Enum.map(fn schema_content ->
      ContentGenerator.modules_content_from_schema(schema_content, &read_schema_fun/1)
    end)
    # For now we just override maps keys
    |> Enum.reduce(%{}, fn map, acc ->
      Map.merge(acc, map)
    end)
    |> Enum.each(&write_module(&1, target_path))

    :ok
  end

  defp write_module({module_name, module_content}, target_path) do
    filename = String.replace(module_name, ".", "/")

    module_path = Path.join(target_path, "#{filename}.ex")
    File.mkdir_p!(Path.dirname(module_path))

    File.write!(module_path, module_content)
    ShellIO.info("Generated #{module_path}")
  end

  defp read_schema_fun(_type) do
    # TODO To implement
    ""
  end
end
