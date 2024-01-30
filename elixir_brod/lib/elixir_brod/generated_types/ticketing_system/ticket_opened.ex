defmodule ElixirBrod.GeneratedTypes.TicketingSystem.TicketOpened do
  @moduledoc """
  _*Please note: This module was generated automatically through a task, it
  makes no sense to make changes here, but you should directly modify
  the avro file from which it was generated.*_

  TODO: Add description
  """

  @typedoc """
  The ElixirBrod.GeneratedTypes.TicketingSystem.TicketOpened module expose a `struct` with the following fields:
    `:ticket_id` - _*no description provided in the avro file*_
    `:occurred_on` - _*no description provided in the avro file*_
    `:requester` - _*no description provided in the avro file*_

  """

  @type t :: %__MODULE__{
    ticket_id: UUid.t(),
    occurred_on: DateTime.t(),
    requester: ElixirBrod.GeneratedTypes.TicketingSystem.Requester.t()
  }

  defstruct [:ticket_id, :occurred_on, :requester]
  @spec create(data :: map()) :: {:ok, t()} | {:error, any()}
  def create(data),
    do: data
    |> then(&ElixirBrod.Utils.Map.transform(&1))
    |> then(&struct(__MODULE__, &1))
    |> validate()

  @spec validate(t()) :: {:ok, t()} | {:error, any()}
  def validate(data) do
    {parsed_data, _} = {[], data}
        |> ElixirBrod.Avro.Validation.Simple.validate(:ticket_id, %ElixirBrod.Avro.SchemaParser.Field{type: :string, name: "ticket_id", logical_type: :uuid, precision: nil, scale: nil, size: nil, bytes: "", description: nil, symbols: [], items: [], has_default?: false, default: nil, fields: []})
        |> ElixirBrod.Avro.Validation.Simple.validate(:occurred_on, %ElixirBrod.Avro.SchemaParser.Field{type: :long, name: "occurred_on", logical_type: :"timestamp-millis", precision: nil, scale: nil, size: nil, bytes: "", description: nil, symbols: [], items: [], has_default?: false, default: nil, fields: []})
        |> ElixirBrod.Avro.Validation.Complex.validate(:requester, %ElixirBrod.Avro.SchemaParser.Field{type: {:record, "ticketing_system"}, name: "requester", logical_type: nil, precision: nil, scale: nil, size: nil, bytes: "", description: nil, symbols: [], items: [], has_default?: false, default: nil, fields: [%ElixirBrod.Avro.SchemaParser.Field{type: :string, name: "email", logical_type: nil, precision: nil, scale: nil, size: nil, bytes: "", description: nil, symbols: [], items: [], has_default?: false, default: nil, fields: []}, %ElixirBrod.Avro.SchemaParser.Field{type: :string, name: "name", logical_type: nil, precision: nil, scale: nil, size: nil, bytes: "", description: nil, symbols: [], items: [], has_default?: false, default: nil, fields: []}, %ElixirBrod.Avro.SchemaParser.Field{type: [:null, :string], name: "middlename", logical_type: nil, precision: nil, scale: nil, size: nil, bytes: "", description: nil, symbols: [], items: [], has_default?: false, default: nil, fields: []}, %ElixirBrod.Avro.SchemaParser.Field{type: :string, name: "surname", logical_type: nil, precision: nil, scale: nil, size: nil, bytes: "", description: nil, symbols: [], items: [], has_default?: false, default: nil, fields: []}, %ElixirBrod.Avro.SchemaParser.Field{type: :int, name: "age", logical_type: nil, precision: nil, scale: nil, size: nil, bytes: "", description: nil, symbols: [], items: [], has_default?: false, default: nil, fields: []}]})
    case Enum.group_by(parsed_data, &elem(&1, 0), &Tuple.delete_at(&1, 0)) do
      %{error: errors} ->
	{:error, errors}
      %{ok: values} ->
        {:ok, struct(__MODULE__, values)}
    end
  end
end
