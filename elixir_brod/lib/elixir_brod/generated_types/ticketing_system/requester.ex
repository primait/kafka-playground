defmodule ElixirBrod.GeneratedTypes.TicketingSystem.Requester do
  @moduledoc """
  _*Please note: This module was generated automatically through a task, it
  makes no sense to make changes here, but you should directly modify
  the avro file from which it was generated.*_

  TODO: Add description
  """

  @typedoc """
  The ElixirBrod.GeneratedTypes.TicketingSystem.Requester module expose a `struct` with the following fields:
    `:email` - _*no description provided in the avro file*_
    `:name` - _*no description provided in the avro file*_
    `:middlename` - _*no description provided in the avro file*_
    `:surname` - _*no description provided in the avro file*_
    `:age` - _*no description provided in the avro file*_

  """

  @type t :: %__MODULE__{
    email: String.t(),
    name: String.t(),
    middlename: nil | String.t(),
    surname: String.t(),
    age: integer()
  }

  defstruct [:email, :name, :middlename, :surname, :age]
  @spec create(data :: map()) :: {:ok, t()} | {:error, any()}
  def create(data),
    do: data
    |> then(&ElixirBrod.Utils.Map.transform(&1))
    |> then(&struct(__MODULE__, &1))
    |> validate()

  @spec validate(t()) :: {:ok, t()} | {:error, any()}
  def validate(data) do
    {parsed_data, _} = {[], data}
        |> ElixirBrod.Avro.Validation.Simple.validate(:email, %ElixirBrod.Avro.SchemaParser.Field{type: :string, name: "email", logical_type: nil, precision: nil, scale: nil, size: nil, bytes: "", description: nil, symbols: [], items: [], has_default?: false, default: nil, fields: []})
        |> ElixirBrod.Avro.Validation.Simple.validate(:name, %ElixirBrod.Avro.SchemaParser.Field{type: :string, name: "name", logical_type: nil, precision: nil, scale: nil, size: nil, bytes: "", description: nil, symbols: [], items: [], has_default?: false, default: nil, fields: []})
        |> ElixirBrod.Avro.Validation.Complex.validate(:middlename, %ElixirBrod.Avro.SchemaParser.Field{type: [:null, :string], name: "middlename", logical_type: nil, precision: nil, scale: nil, size: nil, bytes: "", description: nil, symbols: [], items: [], has_default?: false, default: nil, fields: []})
        |> ElixirBrod.Avro.Validation.Simple.validate(:surname, %ElixirBrod.Avro.SchemaParser.Field{type: :string, name: "surname", logical_type: nil, precision: nil, scale: nil, size: nil, bytes: "", description: nil, symbols: [], items: [], has_default?: false, default: nil, fields: []})
        |> ElixirBrod.Avro.Validation.Simple.validate(:age, %ElixirBrod.Avro.SchemaParser.Field{type: :int, name: "age", logical_type: nil, precision: nil, scale: nil, size: nil, bytes: "", description: nil, symbols: [], items: [], has_default?: false, default: nil, fields: []})
    case Enum.group_by(parsed_data, &elem(&1, 0), &Tuple.delete_at(&1, 0)) do
      %{error: errors} ->
	{:error, errors}
      %{ok: values} ->
        {:ok, struct(__MODULE__, values)}
    end
  end
end
