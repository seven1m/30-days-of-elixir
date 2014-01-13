defmodule Fib do
  @moduledoc """
    Lazy Fibonacci Sequence
  """

  defrecord FibVal, val: 0, next: 1

  @doc """
    Return a lazy sequence of FibVals.

    To get the values, use Enum.map &(&1.val)

      iex> Fib.fib |> Enum.take(10) |> Enum.map &(&1.val)
      [0, 1, 1, 2, 3, 5, 8, 13, 21, 34]
  """
  def fib do
    Stream.iterate FibVal.new, fn FibVal[val: val, next: next] ->
      FibVal.new(val: next, next: val + next)
    end
  end
end

ExUnit.start

defmodule RecursionTest do
  use ExUnit.Case
  doctest Fib
end
