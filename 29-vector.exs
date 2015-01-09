defmodule Vector do
  @moduledoc """
  This is my (woefully inadequate) attempt at building a Vector with constant-time
  lookup using a Hash Array Mapped Trie (HAMT).

  While it is blazing fast for getting the value at an index,
  it's way slower (than just using a list) in the case of adding values and iterating.

  Another shortcoming is the hash function will certainly create collisions and
  I didn't bother to account for that in the storage. Sorry :-(

  And last, the tree structure isn't compressed, so it gets big fast... don't bother
  trying to IO.inspect the sucker!

  But this is good enough for a single day's excercise, and I learned a ton
  in the process... Yay for learning! :-)
  """

  @template :erlang.make_tuple(10, nil)

  require Record
  Record.defrecordp :vec, Vector, size: 0, children: {nil, @template}

  @doc """
  Builds a new empty vector.

    iex> Vector.new
    {Vector, 0, {nil, {nil, nil, nil, nil, nil, nil, nil, nil, nil, nil}}}
  """
  def new do
    vec()
  end

  @doc """
  Builds a new vector from the given list.

    iex> v = Vector.new(["tim", "jen", "mac", "kai"])
    iex> Vector.size(v)
    4
    iex> Vector.get(v, 1)
    "jen"
  """
  def new(list) do
    from_list(list, new)
  end

  @doc """
  Builds a new vector with count items initialized to given value

    iex> v = Vector.new(4, "foo")
    iex> Vector.size(v)
    4
    iex> Vector.get(v, 3)
    "foo"
  """
  def new(count, val) do
    Enum.reduce 0..(count-1), new, fn i, v ->
      Vector.put(v, i, val)
    end
  end

  @doc """
  Get the size of the vector.
  """
  def size(vec(size: size)) do
    size
  end

  @doc """
  Gets the value from the vector at the given index.

     iex> v = Vector.put(nil, 10, "tim")
     iex> Vector.get(v, 10)
     "tim"
  """
  def get(vec(children: children), index) do
    do_get(children, hash(index))
  end

  @doc """
  Puts the value in a vector at the given index.

     iex> v = Vector.new
     iex> v = Vector.put(v, 10, "tim")
     iex> Vector.get(v, 10)
     "tim"
  """
  def put(v = vec(size: size, children: children), index, value) do
    children = do_put(children, hash(index), value)
    if index >= size do
      vec(size: index + 1, children: children)
    else
      v
    end
  end
  def put(nil, index, value), do: put(new, index, value)

  @doc """
  Given a vector, an accumulator, and a function, iterate over
  each item in the vector passing the item and the accumulator
  to the function. The function should return the modified
  accumulator.

    iex> v = Vector.new([1,2,3])
    iex> Vector.reduce(v, 0, &(&2 + &1))
    6
  """
  def reduce(v = vec(size: size), acc, fun) do
    Enum.reduce 0..(size-1), acc, fn index, acc ->
      fun.(get(v, index), acc)
    end
  end

  def find(v = vec(size: size), value, index \\ 0) do
    cond do
      index >= size          -> nil
      get(v, index) == value -> index
      true                   -> find(v, value, index+1)
    end
  end

  def from_list(list, v), do: from_list(list, v, 0)
  def from_list([val | rest], v, index) do
    v = put(v, index, val)
    from_list(rest, v, index+1)
  end
  def from_list([], v, _), do: v

  # traversed down to a non-existent key
  defp do_get(nil, _) do
    nil
  end

  # at the last node of our tree, so we should have a value!
  defp do_get({val, _}, []) do
    val
  end

  # traverse down the tree to get the value
  defp do_get({_, children}, [pos | hash_rest]) do
    node = elem(children, pos)
    do_get(node, hash_rest)
  end

  # at the last leaf of our branch, so store the value
  # FIXME our hash function will have collisions, so we really should
  # store duplicates properly here, but we don't yet
  defp do_put(_, [], value) do
    {value, @template}
  end

  # build a new branch
  defp do_put(nil, hash, value) do
    do_put({nil, @template}, hash, value)
  end

  # traverse down the tree to store the value
  defp do_put({val, children}, [pos | hash_rest], value) do
    tree = do_put(elem(children, pos), hash_rest, value)
    {val, put_elem(children, pos, tree)}
  end

  # generate a hash of the index,
  # i.e. a list of positions for each level of depth in the tree
  defp hash(index) do
    chars = index
      |> :erlang.phash2
      |> Integer.to_char_list
    for c <- chars, do: List.to_integer([c])
  end
end

defimpl Enumerable, for: Vector do
  def count(v) do
    {:ok, Vector.size(v)}
  end

  # FIXME this is broke
  def reduce(v, acc, fun) do
    Vector.reduce(v, acc, fun)
  end

  def member?(v, val) do
    {:ok, Vector.index(v, val) != nil}
  end
end

ExUnit.start

defmodule VectorTest do
  use ExUnit.Case

  test "stores a value at an index in a tree structure" do
    v = Vector.new
    v = Vector.put(v, 0, "tim")
    assert v == {Vector, 1, {nil, {
      nil, nil, nil, nil, nil, nil, nil, nil,
      {nil, {
        nil, nil, nil, nil, nil, nil, nil, nil,
        {nil, {
          nil, nil, nil, nil, nil, nil, nil,
          {nil, {
            nil, nil,
            {nil, {
              nil, nil, nil,
              {nil, {
                nil, nil, nil, nil, nil, nil, nil,
                {nil, {
                  nil, nil,
                  {nil, {
                    nil, nil, nil, nil, nil,
                    {"tim", {nil, nil, nil, nil, nil, nil, nil, nil, nil, nil}},
                    nil, nil, nil, nil}},
                  nil, nil, nil, nil, nil, nil, nil}},
                nil, nil}},
              nil, nil, nil, nil, nil, nil}},
            nil, nil, nil, nil, nil, nil, nil}},
          nil, nil}},
        nil}},
      nil}}}
  end

  test "size" do
    v = Vector.new
    v = Vector.put(v, 0, "tim")
    v = Vector.put(v, 1, "jen")
    assert Vector.size(v) == 2
    v = Vector.put(v, 9, "mac")
    assert Vector.size(v) == 10
  end

  test "get" do
    v = Vector.new
    v = Vector.put(v, 0, "tim")
    v = Vector.put(v, 1, "jen")
    v = Vector.put(v, 2, "mac")
    assert Vector.get(v, 0) == "tim"
    assert Vector.get(v, 1) == "jen"
    assert Vector.get(v, 2) == "mac"
  end

  test "get non-existent key" do
    v = Vector.new
    assert Vector.get(v, 10) == nil
  end

  test "count" do
    v = Vector.new([1,2,3])
    assert tuple_size(v) == 3
  end

  test "reduce" do
    v = Vector.new([1,2,3])
    sum = Vector.reduce(v, 0, &(&1 + &2))
    assert sum == 6
  end

  test "find" do
    v = Vector.new([1,2,3])
    index = Vector.find(v, 3)
    assert index == 2
  end

  @size 100_000

  test "creation speed" do
    {microsecs, _} = :timer.tc fn ->
      List.duplicate("foo", @size)
    end
    IO.puts "List creation took #{microsecs} microsecs" # 3,525 microsecs
    {microsecs, _} = :timer.tc fn ->
      Vector.new(@size, "foo")
    end
    IO.puts "Vector creation took #{microsecs} microsecs" # 265,647 microsecs
  end

  test "iteration speed" do
    list = List.duplicate("foo", @size)
    {microsecs, _} = :timer.tc fn ->
      Enum.reduce list, 0, fn _, count -> count + 1 end
    end
    IO.puts "List traversal took #{microsecs} microsecs" # 1605 microsecs
    vector = Vector.new(@size, "foo")
    {microsecs, _} = :timer.tc fn ->
      Vector.reduce vector, 0, fn _, count -> count + 1 end
    end
    IO.puts "Vector traversal took #{microsecs} microsecs" # 105,732 microsecs
  end

  test "access speed" do
    list = List.duplicate("foo", @size)
    {microsecs, _} = :timer.tc fn ->
      assert Enum.at(list, @size-1) == "foo"
    end
    IO.puts "List access took #{microsecs} microsecs" # 997 microsecs
    vector = Vector.new(@size, "foo")
    {microsecs, _} = :timer.tc fn ->
      assert Vector.get(vector, @size-1) == "foo"
    end
    IO.puts "Vector access took #{microsecs} microsecs" # 3 microsecs
  end
end
