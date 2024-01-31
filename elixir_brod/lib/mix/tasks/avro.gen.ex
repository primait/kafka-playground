defmodule Mix.Tasks.Avro.Gen do
  use Mix.Task

  alias ElixirBrod.Avro.ModuleWriter.Conventions
  alias ElixirBrod.Avro.ModuleWriter.Metadata
  alias ElixirBrod.Avro.SchemaParser

  @impl true
  def run(_args) do
    # TODO read this from args
    schemas_folder_path = "./schemas/"

    #TODO decide if this should be a path or just a folder
    target_folder = "generated_types"

    schemas_folder_path
    |> ls_r()
    |> Enum.each(&generate_module(&1, target_folder))
  end

  defp generate_module(file_path, target_folder) do
    metadata =
      case SchemaParser.parse(File.read!(file_path), target_folder) do
        {:ok, metadata} -> metadata
        error -> raise error
      end

    write_module(metadata)

    metadata.fields
    |> Enum.filter(fn
      %{type: {:record, _}} -> true
      _ -> false
    end)
    |> Enum.each(
      &write_module(ElixirBrod.Avro.SchemaParser.Record.from_field(&1, metadata.base_path))
    )
  end

  @spec write_module(
          ElixirBrod.Avro.SchemaParser.Record.t()
          | ElixirBrod.Avro.SchemaParser.MessageEnum.t()
        ) :: :ok
  defp write_module(metadata) do
    file = Conventions.generate_path!(metadata)
    File.mkdir_p!(Path.dirname(file))
    File.write(file, Metadata.to_string(metadata))
  end

  def ls_r(path \\ ".") do
    cond do
      File.regular?(path) ->
        [path]

      File.dir?(path) ->
        File.ls!(path)
        |> Enum.map(&Path.join(path, &1))
        |> Enum.map(&ls_r/1)
        |> Enum.concat()

      true ->
        []
    end
  end
end
