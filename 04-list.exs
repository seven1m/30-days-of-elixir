# http://elixir-lang.org/getting-started/basic-types.html

ExUnit.start

defmodule ListTest do
  use ExUnit.Case

  def sample() do
    ["Tim", "Jen", "Mac", "Kai"]
  end

  test "sigil" do
    assert sample() == ~w(Tim Jen Mac Kai)
  end

  test "head" do
    [head | _] = sample()
    assert head == "Tim"
  end

  test "tail" do
    [_ | tail] = sample()
    assert tail == ~w(Jen Mac Kai)
  end

  # warning, has to traverse the entire list!
  test "last item" do
    assert List.last(sample()) == "Kai"
  end

  test "delete item" do
    assert List.delete(sample(), "Mac") == ~w(Tim Jen Kai)
    # only deletes the first occurrence
    assert List.delete([1, 2, 2, 3], 2) == [1, 2, 3]
  end

  test "List.fold" do
    list = [20, 10, 5, 2.5]
    sum = List.foldr list, 0, &(&1 + &2)
    # or...
    # sum = List.foldr list, 0, fn (num, sum) -> num + sum end
    assert sum == 37.5
  end

  # Seems that Enum module methods are encouraged over List methods
  # (if possible)
  test "Enum.reduce" do
    list = [20, 10, 5, 2.5]
    sum = Enum.reduce list, 0, &(&1 + &2)
    # or...
    # sum = Enum.reduce list, 0, fn (num, sum) -> num + sum end
    assert sum == 37.5
  end

  # List.wrap is much like Ruby's Array() method
  test "wrap" do
    assert List.wrap(sample()) == sample()
    assert List.wrap(1) == [1]
    assert List.wrap([]) == []
    assert List.wrap(nil) == []
  end

  test "list comprehension" do
    some = for n <- sample(), String.first(n) < "M", do: n <> " Morgan"
    assert some == ["Jen Morgan", "Kai Morgan"]
  end

  # I was curious about raw speed of working with large lists...
  # Let's just build and reverse a large list.
  # Suprisingly, the manual way is not much slower.

  # Also got to browse Erlang docs for timer:tc/1
  # (http://www.erlang.org/doc/man/timer.html#tc-1) and call thru from Elixir.
  # Easy!

  test "manual reverse speed" do
    {microsec, reversed} = :timer.tc fn ->     # Erlang function, yay!
      Enum.reduce 1..1_000_000, [], fn (i, l) -> List.insert_at(l, 0, i) end
    end
    assert reversed == Enum.to_list(1_000_000..1)
    IO.puts "manual reverse took #{microsec} microsecs"
  end

  # Another thing worth pointing out is it's cheap to insert at the front of a
  # list while it's expensive to insert at the end of a list (which is O(n)).
  test "speed of inserting at the end of a list" do
    {microsec, reversed} = :timer.tc fn ->     # Erlang function, yay!
      # It takes about 1.6 seconds on my laptop even with only 10000 elements.
      # For 1..1_000_000, it would take a really long time.
      Enum.reduce 1..10000, [], fn (i, l) -> List.insert_at(l, -1, i) end
    end
    assert reversed == Enum.to_list(1..10000)
    IO.puts "inserting at the end of a list took #{microsec} microsecs"
  end

  test "Enum.reverse speed" do
    {microsec, reversed} = :timer.tc fn ->
      Enum.reverse 1..1_000_000
    end
    assert reversed == Enum.to_list(1_000_000..1)
    IO.puts "Enum.reverse took #{microsec} microsecs"
  end
end
