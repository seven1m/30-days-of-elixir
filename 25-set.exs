ExUnit.start

defmodule SetTest do
  use ExUnit.Case

  test "to_list" do
    list = HashSet.new([1, 2, 2, 3]) |> HashSet.to_list
    assert list == [2, 3, 1] # unintuitive ordering
  end

  test "union" do
    union = HashSet.new([1, 2, 3]) |> HashSet.union(HashSet.new([2, 3, 4]))
    assert Set.to_list(union) == [2, 3, 4, 1] # unintuitive, but somewhat more understandable
  end

  test "intersection" do
    union = HashSet.new([1, 2, 3]) |> HashSet.intersection(HashSet.new([2, 3, 4]))
    assert Set.to_list(union) == [2, 3]
  end

  test "member?" do
    refute HashSet.new([1, 3, 5]) |> HashSet.member?(2)
  end
end
