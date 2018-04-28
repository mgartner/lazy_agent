defmodule LazyAgentTest do
  use ExUnit.Case
  doctest LazyAgent

  test "greets the world" do
    assert LazyAgent.hello() == :world
  end
end
