ExUnit.start

defmodule SetTest do
  use ExUnit.Case

  test "to_list" do
    list = Enum.into([1, 2, 2, 3], HashSet.new) |> HashSet.to_list
    assert list == [2, 3, 1] # unintuitive ordering
  end

  test "union" do
    union = Enum.into([1, 2, 3], HashSet.new) |> HashSet.union(Enum.into([2, 3, 4], HashSet.new))
    assert Set.to_list(union) == [2, 3, 4, 1] # unintuitive, but somewhat more understandable
  end

  test "intersection" do
    union = Enum.into([1, 2, 3], HashSet.new) |> HashSet.intersection(Enum.into([2, 3, 4], HashSet.new))
    assert Set.to_list(union) == [2, 3]
  end

  test "member?" do
    refute Enum.into([1, 3, 5], HashSet.new) |> HashSet.member?(2)
  end
end
