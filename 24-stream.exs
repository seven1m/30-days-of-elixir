defmodule Fib do
  @moduledoc """
    Lazy Fibonacci Sequence
  """

  defmodule FibVal do
    defstruct val: 0, next: 1
  end

  @doc """
    Return a lazy sequence of FibVals.

    To get the values, use map &(&1.val)

      iex> Fib.fib |> Stream.map(&(&1.val)) |> Enum.take(10)
      [0, 1, 1, 2, 3, 5, 8, 13, 21, 34]
  """
  def fib do
    Stream.iterate %FibVal{}, fn %FibVal{val: val, next: next} ->
      %FibVal{val: next, next: val + next}
    end
  end

  @doc """
    Return a lazy sequence of Fibonacci numbers

    This one is better as it returns the actual integer value
    and doesn't use FibVal, thanks to Stream.unfold/2

      iex> Fib.fib2 |> Enum.take(10)
      [0, 1, 1, 2, 3, 5, 8, 13, 21, 34]
  """
  def fib2 do
    Stream.unfold({0, 1}, fn {a, b} -> {a, {b, a + b}} end)
  end
end

ExUnit.start

defmodule FibTest do
  use ExUnit.Case

  test "fib" do
    fib = Fib.fib |> Stream.map(&(&1.val)) |> Enum.take(10)
    assert fib == [0, 1, 1, 2, 3, 5, 8, 13, 21, 34]
  end

  test "fib2" do
    fib = Fib.fib2 |> Enum.take(10)
    assert fib == [0, 1, 1, 2, 3, 5, 8, 13, 21, 34]
  end
end
