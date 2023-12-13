defmodule ElixirBrod.Avro.Type.Duration do
  @moduledoc """
  This module exposes the representation of an Avro Duration in Elixir
  """

  @typedoc """
  A duration in Avro is expressed using three integers: months, days, and milliseconds.

  If a two-month duration is applied to January 1, 1970, we would get March 1, 1970,
  thus it would be a 59-day interval. However, applying it to March 1st would result in 61 days.

  This is to illustrate why the duration is not represented as a simple integer with milliseconds.
  """
  @type t :: %__MODULE__{
          month: integer(),
          days: integer(),
          millis: integer()
        }

  @enforce_keys [:month, :days, :millis]
  defstruct [month: 0, days: 0, millis: 0]

  def apply_to(%__MODULE__{millis: ms}, %Time{} = time),
      do: Timex.shift(time, milliseconds: ms)

  def apply_to(%__MODULE__{month: m, days: d, millis: ms}, %Date{} = date),
      do: Timex.shift(date, months: m, days: d, milliseconds: ms)

  def apply_to(%__MODULE__{month: m, days: d, millis: ms}, %NaiveDateTime{} = date),
      do: Timex.shift(date, months: m, days: d, milliseconds: ms)

  def apply_to(%__MODULE__{month: m, days: d, millis: ms}, %DateTime{} = date),
      do: Timex.shift(date, months: m, days: d, milliseconds: ms)
end
