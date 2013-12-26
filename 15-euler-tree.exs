defmodule Tree do
  @moduledoc """
  Project Euler - Problem 67

  By starting at the top of the triangle below and moving to adjacent numbers on the row below, the maximum total from top to bottom is 23.

     3
    7 4
   2 4 6
  8 5 9 3

  That is, 3 + 7 + 4 + 9 = 23.

  Find the maximum total from top to bottom in tree.txt, a 15K text file containing a triangle with one-hundred rows.
  """

  def maximal_path([row, comparison_row | rest_rows]) do
    row = reduce_row(row, comparison_row)
    maximal_path([row | rest_rows])
  end
  def maximal_path([row]), do: Enum.first(row)

  def from_file(filename) do
    File.read!(filename)
      |> String.strip
      |> String.split("\n")
      |> Enum.reverse
      |> Enum.map(fn row ->
        lc num inlist String.split(row, " "), do: binary_to_integer(num)
      end)
  end

  def reduce_row(row, comparison_row) do
    lc {main, opt1, opt2} inlist pairs(row, comparison_row) do
      Enum.max([main + opt1, main + opt2])
    end
  end

  def pairs(row, comparison_row) do
    lc {num, index} inlist Enum.with_index(comparison_row) do
      [{num, Enum.at(row, index), Enum.at(row, index+1)}]
    end |> List.flatten
  end
end

ExUnit.start

defmodule TreeTest do
  use ExUnit.Case

  @path Path.expand("../support/tree.txt", __FILE__)

  test "read file" do
    tree = Tree.from_file(@path)
    assert length(tree) == 100
    assert Enum.at(tree, 99) == [59]
  end

  test "pairs" do
    assert Tree.pairs([8, 5, 9, 3], [2, 4, 6]) == [{2, 8, 5}, {4, 5, 9}, {6, 9, 3}]
  end

  test "reduce row" do
    row1 = [30, 11, 85, 31, 34, 71, 13, 48, 05, 14, 44, 03, 19, 67, 23]
    row2 = [23, 33, 44, 81, 80, 92, 93, 75, 94, 88, 23, 61, 39, 76, 22, 03]
    assert Tree.reduce_row(row2, row1) == [63, 55, 166, 112, 126, 164, 106, 142, 99, 102, 105, 64, 95, 143, 45]
  end

  test "maximal path" do
    tree = Tree.from_file(@path)
    assert Tree.maximal_path(tree) == 7273
  end
end
