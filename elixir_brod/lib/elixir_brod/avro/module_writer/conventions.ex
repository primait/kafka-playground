defmodule ElixirBrod.Avro.ModuleWriter.Conventions do
  @moduledoc """
  This module exposes all the conventions that we will establish over
  time, such as the convention inherent to the file path or the module
  name.
  """

  @doc """
  This function exposes the convention with which we decide the path of
  the file.
  """
  @spec generate_path!(%{base_path: String.t(), name: String.t(), namespace: String.t()}) ::
          String.t()
  @spec generate_path!(Path.t(), String.t(), String.t()) :: String.t()
  def generate_path!(%_{base_path: base_path, name: name, namespace: namespace}),
    do: generate_path!(base_path, name, namespace)

  def generate_path!(base_path, name, namespace) do
    name = Macro.underscore(name)

    namespace =
      namespace
      |> Macro.underscore()
      |> String.replace(".", "/")

    Path.join(["lib/elixir_brod", base_path, namespace, "#{name}.ex"])
  end

  def fully_qualified_module_name(%_{} = struct),
    do: struct |> generate_path!() |> fully_qualified_module_name

  def fully_qualified_module_name("lib/" <> path),
    do:
      path
      |> String.trim_trailing(".ex")
      |> String.split("/")
      |> Enum.map(&Macro.camelize/1)
      |> Enum.join(".")
end
