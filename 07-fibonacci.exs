defmodule Fib do
  @moduledoc """
  Fibonacci Sequence function.
  Please note, I wrote this purely from memory --
  I mean, I'm sure there's a more concise way to build this algorithm. :-)
  """

  @seed [0, 1]

  # named functions can have different arities, whereas anonymous functions cannot
  # also, anonymous functions cannot call themselves recursively :-(

  def fib(n) when n < 2 do
    Enum.take @seed, n
  end

  def fib(n) when n >= 2 do
    fib(@seed, n - 2)
  end

  def fib(acc, 0), do: acc

  def fib(acc, n) do
    fib(acc ++ [Enum.at(acc, -2) + Enum.at(acc, -1)], n - 1)
  end
end

defmodule Fib2 do
  @moduledoc """
  Fibonacci Sequence function.
  This is my attempt to be more efficient by building the list
  backwards (and then reversing at the end).
  """

  @seed [1, 0]

  def fib2(n) when n < 2 do
    Enum.reverse(@seed) |> Enum.take(n)
  end

  def fib2(n) when n >= 2 do
    fib2(@seed, n - 2)
  end

  def fib2(acc, 0), do: Enum.reverse(acc)

  def fib2([first, second | _] = lst, n) do
    fib2([first + second | lst], n - 1)
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

  import Fib2

  test "fibonacci 2" do
    assert fib2(0) == []
    assert fib2(1) == [0]
    assert fib2(2) == [0, 1]
    assert fib2(10) == [0, 1, 1, 2, 3, 5, 8, 13, 21, 34]
  end

  test "benchmark" do
    {microsecs, _} = :timer.tc fn -> fib(1000) end
    IO.puts "fib() took #{microsecs} microsecs"     # 7118 microsecs
    {microsecs, _} = :timer.tc fn -> fib2(1000) end
    IO.puts "fib2() took #{microsecs} microsecs"    # 90 microsecs
  end
end
