defmodule LazyAgent do
  @moduledoc File.read!("#{__DIR__}/../README.md")

  defstruct started?: false,
            start_fun: nil,
            state: nil

  @type state :: term
  @type agent :: Agent.agent()

  @type start_fun :: (() -> state)

  @type t :: %__MODULE__{
          started?: boolean,
          start_fun: start_fun,
          state: state
        }

  @doc """
  Starts an agent without links, initializing the state with the given
  function, similar to `Agent.start/2`.
  """
  @spec start(start_fun, GenServer.options()) :: Agent.on_start()
  def start(fun, options \\ []) do
    if Application.get_env(:lazy_agent, :enabled?) do
      Agent.start(
        fn ->
          %__MODULE__{started?: false, start_fun: fun}
        end,
        options
      )
    else
      Agent.start(fun, options)
    end
  end

  @doc """
  Starts an agent linked to the current process with the given function,
  similar to `Agent.start_link/2`.
  """
  @spec start_link(start_fun, GenServer.options()) :: Agent.on_start()
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
  Gets an agent value via the given anonymous function, similar to
  `Agent.get/3`.

  The function fun is sent to the agent which invokes the function passing the
  agent state. The result of the function invocation is returned from this
  function.

  If the agent's state was not previously initialized, it will be initialized
  exactly once for the first call to `LazyAgent.get/3`.

  ## Examples

      iex> {:ok, pid} = LazyAgent.start_link(fn -> 42 end)
      iex> LazyAgent.get(pid, fn state -> state end)
      42

      iex> LazyAgent.start_link(fn -> 42 end, name: :lazy)
      iex> LazyAgent.get(:lazy, fn state -> state end)
      42

  """
  @spec get(agent, (state -> term), timeout()) :: term
  def get(agent, fun, timeout \\ 5000) do
    if Application.get_env(:lazy_agent, :enabled?) do
      Agent.get_and_update(
        agent,
        fn lazy_state ->
          prepared_lazy_state = prepare(lazy_state)
          get_value = fun.(prepared_lazy_state.state)
          {get_value, prepared_lazy_state}
        end,
        timeout
      )
    else
      Agent.get(agent, fun, timeout)
    end
  end

  @doc """
  Updates the agent state via the given anonymous function, similar to
  `Agent.update/3`.

  The return value of `fun` becomes the new state of the agent.

  If the agent's state was not previously initialized, it will be initialized
  exactly once for the first call to `LazyAgent.update/3`.

  ## Examples

      iex> {:ok, pid} = LazyAgent.start_link(fn -> 42 end)
      iex> LazyAgent.update(pid, fn state -> state + 5 end)
      :ok
      iex> LazyAgent.get(pid, fn state -> state end)
      47

  """
  @spec update(Agent.agent(), (state -> state), timeout()) :: term
  def update(agent, fun, timeout \\ 5000) do
    if Application.get_env(:lazy_agent, :enabled?) do
      Agent.update(
        agent,
        fn lazy_state ->
          prepared_lazy_state = prepare(lazy_state)
          new_value = fun.(prepared_lazy_state.state)
          %__MODULE__{prepared_lazy_state | state: new_value}
        end,
        timeout
      )
    else
      Agent.update(agent, fun, timeout)
    end
  end

  @doc """
  Gets and updates the agent state in one operation via the given anonymous
  function, similar to `Agent.get_and_update/3`.

  The function `fun` must return a tuple with two elements, the first being the
  value to return and the second being the new state of the agent.

  If the agent's state was not previously initialized, it will be initialized
  exactly once for the first call to `LazyAgent.update/3`.

  ## Examples

      iex> {:ok, pid} = LazyAgent.start_link(fn -> 42 end)
      iex> LazyAgent.get_and_update(pid, fn state -> {state, state + 5} end)
      42
      iex> LazyAgent.get(pid, fn state -> state end)
      47

  """
  @spec get_and_update(Agent.agent(), (state -> {term, state}), timeout()) :: term
  def get_and_update(agent, fun, timeout \\ 5000) do
    if Application.get_env(:lazy_agent, :enabled?) do
      Agent.get_and_update(
        agent,
        fn lazy_state ->
          prepared_lazy_state = prepare(lazy_state)

          case fun.(prepared_lazy_state.state) do
            {current_value, new_value} ->
              {current_value, %__MODULE__{prepared_lazy_state | state: new_value}}

            other ->
              other
          end
        end,
        timeout
      )
    else
      Agent.get_and_update(agent, fun, timeout)
    end
  end

  @doc """
  Synchronously stops the agent with the given `reason`, similar to
  `Agent.stop/3`.
  """
  @spec stop(agent, reason :: term, timeout) :: :ok
  defdelegate stop(agent, reason \\ :normal, timeout \\ :infinity), to: Agent

  @spec prepare(t()) :: t()
  defp prepare(lazy_state = %__MODULE__{started?: true}), do: lazy_state

  defp prepare(lazy_state = %__MODULE__{started?: false, start_fun: fun}) do
    state = fun.()
    %__MODULE__{lazy_state | started?: true, state: state}
  end
end
