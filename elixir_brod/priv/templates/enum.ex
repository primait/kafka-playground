defmodule <%= ElixirBrod.Avro.ModuleWriter.Conventions.fully_qualified_module_name(metadata) %> do

  @moduledoc """
  _*Please note: This module was generated automatically through a task, it
  makes no sense to make changes here, but you should directly modify
  the avro file from which it was generated.*_

  TODO: Add description
  """

  @type t :: <%= metadata.symbols
  |> Enum.map(&inspect/1)
  |> Enum.join(" | ") %>

  @values <%= inspect metadata.symbols %>

  @spec valid?(term()) :: boolean()
  def valid?(value) when value in @values, do: true
  def valid?(_), do: false

  @spec create(String.t() | atom()) :: {:ok, t} | {:error, :invalid}
  def create(value) when is_atom(value) and value in @values, do: {:ok, value}

  def create(value) when is_binary(value) do
    value = String.to_existing_atom(value)
    if value in @values, do: {:ok, value}, else: {:error, :invalid}
  rescue
     _ ->
       {:error, :invalid}
  end

<%= if metadata.default do %>
  @spec default :: t
  def default, do: <%= inspect metadata.default %>
<% end %>
end
