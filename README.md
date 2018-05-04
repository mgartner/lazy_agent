# LazyAgent

![Hex.pm](https://img.shields.io/hexpm/v/lazy_agent.svg)
[![Build Docs](https://img.shields.io/badge/hexdocs-release-blue.svg)](https://hexdocs.pm/lazy_agent/LazyAgent.html)
[![Build Status](https://travis-ci.org/mgartner/lazy_agent.svg?branch=master)](https://travis-ci.org/mgartner/lazy_agent)

LazyAgent wraps Elixir's Agent library to allow delayed execution of the
initial state generator function until the first time the Agent process is
accessed.

It is intended to be used in test environments of applications with agents that
have initialization functions that take hundreds of milliseconds or more to
execute. When developing and running a subset of the test suite, these type of
agents can significantly increase the time it takes to run tests, which slows
down development. Using LazyAgent allows execution of only the initialization
functions necessary to run the test subset.

## Installation

Install LazyAgent by adding `lazy_agent` to your list of dependencies in
`mix.exs`:

```elixir
def deps do
  [
    {:lazy_agent, "~> 0.1.0"}
  ]
end
```

## Configuration

To enable or disable LazyAgent, add the following to an environment
configuration file:

```elixir
use Mix.Config

config :lazy_agent, enabled?: true
```

LazyAgent supports [Confex](https://github.com/Nebo15/confex)-style configs, so
you can rely on environment variables:

```elixir
use Mix.Config

config :lazy_agent,
  enabled?: {:system, :boolean, "ENABLE_LAZY_AGENT", true}
```

## Usage

Currently, LazyAgent supports the lazy equivalents of:

* `Agent.start/2`
* `Agent.start_link/2`
* `Agent.get/3`
* `Agent.update/3`
* `Agent.get_and_update/3`
* `Agent.stop/3`

```elixir
iex> {:ok, pid} = LazyAgent.start_link(fn -> 42 end)
iex> LazyAgent.get(pid, fn state -> state end)
42

iex> LazyAgent.start_link(fn -> 42 end, name: :lazy)
iex> LazyAgent.update(:lazy, fn state -> state + 5 end)
:ok
iex> LazyAgent.get(:lazy, fn state -> state end)
47

iex> {:ok, pid} = LazyAgent.start(fn -> 42 end)
iex> LazyAgent.get_and_update(pid, fn state -> {state, state + 5} end)
42
iex> LazyAgent.get(pid, fn state -> state end)
47
iex> LazyAgent.stop(pid)
:ok
```

