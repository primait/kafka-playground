defmodule ElixirBrod.Producer do
  @moduledoc """
  This module exposes the behavior of a possible producer, the API for
  now is cut around the `:brod` API.
  """

  @callback produce_sync(
              client_name :: atom(),
              topic_name :: String.t(),
              partition_or_partition_function :: integer() | atom(),
              key :: String.t(),
              value :: iodata() | %{:value => iodata(), :headers => [{binary(), binary()}]}
            ) :: :ok | {:error, any()}
end
