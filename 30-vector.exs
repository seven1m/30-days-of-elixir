# persistent bit-partitioned vector trie
# http://hypirion.com/musings/understanding-persistent-vector-pt-1 (and part 2)

defmodule Vector do
  import Bitwise

  @bits 2
  @width 1 <<< @bits # 32-way branching
  @mask @width - 1

  defrecordp :vec, Vector, size: 0, depth: 0, tree: []

  @doc """
  Builds a new empty vector.

    iex> Vector.new
    {Vector, 0, 0, []}
  """
  def new do
    vec()
  end

  @doc """
  Builds a new vector from the given list.

    iex> Vector.new(["tim", "jen"])
    {Vector, 2, 1, ["tim", "jen"]}
  """
  def new(list) do
    depth = Float.ceil(length(integer_to_list((length(list) - 1), 2)) / @bits)
    vec(size: length(list), depth: depth, tree: tree_from_list(list, depth))
  end

  @doc """
  Get the size of the vector.

    iex> v = Vector.new([1, 2, 3])
    iex> Vector.size(v)
    3
  """
  def size(vec(size: size)) do
    size
  end

  @doc """
  Gets the value from the vector at the given index.

     iex> v = Vector.new(["tim", "jen", "mac", "kai"])
     iex> Vector.get(v, 2)
     "mac"
  """
  def get(vec(depth: depth, tree: tree), index) do
    _get(tree, key(index, depth))
  end

  @doc """
  Puts the value in a vector at the given index.

     iex> v = Vector.new
     iex> v = Vector.put(v, 0, "tim")
     iex> Vector.get(v, 0)
     "tim"
  """
  def put(vec(size: size, depth: depth, tree: tree), index, value) do
    if index > size, do: raise "index too large"
    if index == size, do: size = index + 1
    # grow tree
    if size > depth * @width do
      depth = depth + 1
      tree = [tree]
    end
    # attach node
    tree = _put tree, key(index, depth), value
    vec(size: size, depth: depth, tree: tree)
  end

  defp key(index, depth, indeces // []) when depth > 0 do
    level = (depth - 1) * @bits
    indeces = indeces ++ [(index >>> level) &&& @mask]
    key(index, depth - 1, indeces)
  end
  defp key(_, _, indeces), do: indeces

  defp tree_from_list(list, depth) when depth > 1 do
    list
      |> Enum.chunk(@width)
      |> tree_from_list(depth - 1)
  end
  defp tree_from_list(list, _), do: list

  defp _get(node, [idx | rest_key]) do
    node = Enum.at(node, idx)
    _get(node, rest_key)
  end
  defp _get(node, []), do: node

  defp _put(tree, [idx | rest_key], value) do
    rest = _put(Enum.at(tree, idx) || [], rest_key, value)
    if length(tree) <= idx do # expand this node
      tree = tree ++ List.duplicate(nil, idx - length(tree) + 1)
    end
    List.replace_at tree, idx, rest
  end
  defp _put(_, [], value), do: value
end

ExUnit.start

defmodule VectorTest do
  use ExUnit.Case
  doctest Vector

  test "put" do
    v = Vector.new
    v = Vector.put(v, 0, "first")
    assert v == {Vector, 1, 1, ["first"]}
    v = Vector.put(v, 1, "second")
    assert v == {Vector, 2, 1, ["first", "second"]}
    v = Vector.put(v, 2, "third")
    assert v == {Vector, 3, 1, ["first", "second", "third"]}
    v = Vector.put(v, 3, "fourth")
    assert v == {Vector, 4, 1, ["first", "second", "third", "fourth"]}
    v = Vector.put(v, 4, "fifth")
    assert v == {Vector, 5, 2, [["first", "second", "third", "fourth"], ["fifth"]]}
    v = Vector.put(v, 2, "third changed")
    assert v == {Vector, 5, 2, [["first", "second", "third changed", "fourth"], ["fifth"]]}
  end

  test "new" do
    v = Vector.new(List.duplicate(1, 64))
    assert v == {Vector, 64, 3, [
      [[1, 1, 1, 1], [1, 1, 1, 1], [1, 1, 1, 1], [1, 1, 1, 1]],
      [[1, 1, 1, 1], [1, 1, 1, 1], [1, 1, 1, 1], [1, 1, 1, 1]],
      [[1, 1, 1, 1], [1, 1, 1, 1], [1, 1, 1, 1], [1, 1, 1, 1]],
      [[1, 1, 1, 1], [1, 1, 1, 1], [1, 1, 1, 1], [1, 1, 1, 1]]
    ]}
  end

  @size 100_000

  test "creation speed" do
    {microsecs, _} = :timer.tc fn ->
      List.duplicate("foo", @size)
    end
    IO.puts "List creation took #{microsecs} microsecs" # 3,462 microsecs
    list = List.duplicate("foo", @size)
    {microsecs, _} = :timer.tc fn ->
      Vector.new(list)
    end
    IO.puts "Vector creation took #{microsecs} microsecs" # 19,092 microsecs
  end
end
