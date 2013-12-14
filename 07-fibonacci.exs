defmodule Fib do
  @moduledoc "Fibonacci Sequence function. Please note, I wrote this purely from memory -- I mean, I'm sure there's a more concise way to build this algorithm. :-)"

  @seed [0, 1]

  # named functions can have different arities, whereas anonymous functions cannot
  # also, anonymous functions cannot call themselves recursively :-(

  def fib(acc, 0), do: acc

  def fib(n) when n < 2 do
    Enum.take @seed, n
  end

  def fib(n) when n >= 2 do
    fib(@seed, n - 2)
  end

  def fib(acc, n) do
    fib(acc ++ [Enum.at(acc, -2) + Enum.at(acc, -1)], n - 1)
  end
end

ExUnit.start

defmodule RecursionTest do
  use ExUnit.Case

  import Fib

  test "fibonacci" do
    assert fib(0) == []
    assert fib(1) == [0]
    assert fib(2) == [0, 1]
    assert fib(10) == [0, 1, 1, 2, 3, 5, 8, 13, 21, 34]
  end
end
