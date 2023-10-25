defmodule ElixirBrodTest do
  use ExUnit.Case
  doctest ElixirBrod

  test "greets the world" do
    assert ElixirBrod.hello() == :world
  end
end
