defmodule ElixirBrod.Avro.Validation.Complex do
  alias ElixirBrod.Avro.Validation.Simple
  alias ElixirBrod.Avro.SchemaParser.Field

  @simple_types [
    :boolean,
    :bytes,
    :double,
    :float,
    :int,
    :long,
    :null,
    :string,
    :"local-timestamp-micros",
    :"local-timestamp-millis",
    :"time-micros",
    :"time-millis",
    :"timestamp-micros",
    :"timestamp-millis",
    :date,
    :duration,
    :uuid,
    :decimal
  ]

  @type result ::
          {:ok, field_name :: String.t(), field_value :: term()}
          | {:error, field_name :: String.t(), error_message :: String.t()}

  @spec validate(
          {previous_results :: [result()], data :: map()},
          field_name :: String.t(),
          definition :: Field.t()
        ) ::
          {[result()], map()}
  def validate({results, data}, name, %Field{type: type} = definition) do
    %_{^name => value} = data
    validator = get_validator(definition)

    if validator.(value) do
      {[{:ok, name, value} | results], data}
    else
      {[{:error, name, "#{inspect(value)} isn't a valid #{inspect(type)}"} | results], data}
    end
  rescue
    _ ->
      {[{:error, name, :field_not_present} | results], data}
  end

  def get_validator(%Field{type: :array, items: items}) do
    validate_element = validate_element(items)
    &Enum.all?(&1, validate_element)
  end

  def get_validator(%Field{type: :map, items: items}) do
    validate_element = validate_element(items)
    &Enum.all?(&1, fn {_, value} -> validate_element.(value) end)
  end

  def get_validator(%Field{type: types}) when is_list(types), do: validate_element(types)

  defp validate_element(items) do
    Enum.reduce(
      items,
      fn _ -> false end,
      fn
        element, previous_validation when element in @simple_types ->
          fn value -> previous_validation.(value) or Simple.get_validator(element).(value) end

        element, previous_validation ->
          fn value -> previous_validation.(value) or get_validator(element).(value) end
      end
    )
  end
end
