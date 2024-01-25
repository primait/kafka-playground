defmodule <%= ElixirBrod.Avro.ModuleWriter.Conventions.fully_qualified_module_name(metadata) %> do
  @moduledoc """
  _*Please note: This module was generated automatically through a task, it
  makes no sense to make changes here, but you should directly modify
  the avro file from which it was generated.*_

  TODO: Add description
  """

  @typedoc """
  The <%= ElixirBrod.Avro.ModuleWriter.Conventions.fully_qualified_module_name(metadata) %> module expose a `struct` with the following fields:
  <%= for field <- metadata.fields do %>    `:<%= field.name |> String.replace(~r/\s/, "_") %>` - <%= field.description || "_*no description provided in the avro file*_" %>
  <% end %>
  """

  @type t :: %__MODULE__{
    <%= metadata.fields
    |> Enum.map(&parse_field_type(&1, metadata.base_path))
    |> Enum.join(",\n    ")
    |> then(& "    #{&1}")
  %>
  }

  defstruct <%= metadata.fields |> Enum.map(& &1.name |> String.replace(~r/\s/, "_") |> String.to_atom()) |> inspect() %>

  @spec create(data :: map()) :: {:ok, t()} | {:error, any()}
  def create(data),
    do: data
    |> then(&ElixirBrod.Utils.Struct.transform(__MODULE__, &1))
    |> validate()

  @spec validate(t()) :: {:ok, t()} | {:error, any()}
  def validate(data) do
    {parsed_data, _} = {[], data}<%= for field <- metadata.fields do %>
        |> <%= validate(field) %><% end %>

    case Enum.group_by(parsed_data, &elem(&1, 0), &Tuple.delete_at(&1, 0)) do
      %{error: errors} ->
	{:error, errors}
      %{ok: values} ->
        {:ok, struct(__MODULE__, values)}
    end
  end
end
