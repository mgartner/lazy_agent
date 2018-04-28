defmodule LazyAgent do
  @moduledoc """
  TODO
  Documentation for LazyAgent.

  ## Examples

      iex> {:ok, pid} = LazyAgent.start_link(fn -> 42 end)
      iex> LazyAgent.get(pid, fn state -> state end)
      42

      iex> LazyAgent.start_link(fn -> 42 end, name: :lazy)
      iex> LazyAgent.get(:lazy, fn state -> state end)
      42

  """

  defstruct started?: false,
            start_fun: nil,
            state: nil

  @type t :: %__MODULE__{
          started?: boolean,
          start_fun: (() -> any),
          state: any
        }

  @doc """
  TODO
  """
  @spec start_link((() -> any), GenServer.options()) :: Agent.on_start()
  def start_link(fun, options \\ []) do
    if Application.get_env(:lazy_agent, :enabled?) do
      Agent.start_link(
        fn ->
          %__MODULE__{started?: false, start_fun: fun}
        end,
        options
      )
    else
      Agent.start_link(fun, options)
    end
  end

  @doc """
  TODO
  """
  @spec get(Agent.agent(), (any -> any)) :: any
  def get(agent, fun) do
    if Application.get_env(:lazy_agent, :enabled?) do
      Agent.get_and_update(agent, fn lazy_state ->
        new_lazy_state = prepare(lazy_state)
        get_value = fun.(new_lazy_state.state)
        {get_value, new_lazy_state}
      end)
    else
      Agent.get(agent, fun)
    end
  end

  @spec prepare(t()) :: t()
  defp prepare(lazy_state = %__MODULE__{started?: true}), do: lazy_state

  defp prepare(lazy_state = %__MODULE__{started?: false, start_fun: fun}) do
    state = fun.()
    %__MODULE__{lazy_state | started?: true, state: state}
  end
end
