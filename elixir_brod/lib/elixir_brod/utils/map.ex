defmodule ElixirBrod.Utils.Map do
  @moduledoc """
  Transform map with string keys to struct
  """
  def transform(map) when is_map(map) do
    map
    |> Enum.map(fn {key, value} -> {transform_key(key), transform_value(value)} end)
    |> Enum.into(%{})
    |> IO.inspect(label: :result)
  end

  defp transform_key(key) when is_binary(key), do: String.to_atom(key)
  # handles cases where key is already an atom
  defp transform_key(key), do: key

  defp transform_value(%_{} = value), do: value

  defp transform_value(value) when is_map(value),
    do: transform(value)

  # handles non-map values
  defp transform_value(value), do: value
end
