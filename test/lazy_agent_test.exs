defmodule LazyAgentTest do
  use ExUnit.Case
  doctest LazyAgent

  describe "with lazy agent enabled" do
    setup do
      Application.put_env(:lazy_agent, :enabled, true)
    end

    test "start_link/2" do
      start_fun = fn -> 45 end
      {:ok, pid} = LazyAgent.start_link(start_fun)

      assert Agent.get(pid, & &1) == %LazyAgent{started?: false, start_fun: start_fun, state: nil}
    end

    test "get/2" do
      start_fun = fn -> 45 end
      {:ok, pid} = LazyAgent.start_link(start_fun)

      assert LazyAgent.get(pid, & &1) == 45
      assert Agent.get(pid, & &1) == %LazyAgent{started?: true, start_fun: start_fun, state: 45}
    end
  end

  describe "with LazyAgent disabled" do
    setup do
      Application.put_env(:lazy_agent, :enabled, false)
    end

    test "start_link/2" do
      start_fun = fn -> 45 end
      {:ok, pid} = LazyAgent.start_link(start_fun)

      assert LazyAgent.get(pid, & &1) == 45
    end

    test "get/2" do
      start_fun = fn -> 45 end
      {:ok, pid} = LazyAgent.start_link(start_fun)

      assert LazyAgent.get(pid, & &1) == 45
    end
  end
end