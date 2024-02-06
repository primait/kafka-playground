defmodule ElixirAvro.Generator.Types.Date do
  def encode_value!(value) do
    Date.diff(value, ~D[1970-01-01])
  end
end
