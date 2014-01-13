defmodule Fib do
  @moduledoc """
    Lazy Fibonacci Sequence
  """

  @doc """
    Return a lazy sequence of Fibonacci numbers

      iex> Fib.fib |> Enum.take(10)
      [0, 1, 1, 2, 3, 5, 8, 13, 21, 34]
  """
  def fib do
    Stream.unfold({0, 1}, fn {a, b} -> {a, {b, a + b}} end)
  end
end

ExUnit.start

defmodule RecursionTest do
  use ExUnit.Case
  doctest Fib
end
