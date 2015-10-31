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
  def maximal_path([row]), do: List.first(row)

  def from_file(filename) do
    File.read!(filename)
      |> String.strip
      |> String.split("\n")
      |> Enum.reverse
      |> Enum.map(fn row ->
        for num <- String.split(row, " "), do: String.to_integer(num)
      end)
      |> Enum.map(fn row -> append_index(row) end)
  end

  def reduce_row(row, comparison_row) do
    for {{main, index}, {opt1, index1}, {opt2, index2}} <- pairs(row, comparison_row) do
      sum1 = main + opt1
      sum2 = main + opt2
      if sum1 > sum2 do
        {sum1, index ++ index1}
      else
        {sum2, index ++ index2}
      end
    end
  end

  def append_index(row) do
    for {num, index} <- Enum.with_index(row) do
      {num, [index]}
    end
  end

  def pairs(row, comparison_row) do
    for {num, path = [index | _]} <- comparison_row do
      {{num, path}, Enum.at(row, index), Enum.at(row, index+1)}
    end
  end

  def pretty_print(filename) do
    tree = Tree.from_file(filename)
    {sum, path} = Tree.maximal_path(tree)

    IO.puts "maximal sum = #{sum}"

    size = length(Enum.at(tree, 0))

    tree
      |> Enum.reverse
      |> Enum.with_index
      |> Enum.each(fn {row, row_index} ->
        if rem(row_index, 2) == 0, do: IO.write(" ")
        String.duplicate("  ", div(size - length(row), 2)) |> IO.write
        (for {_, [p | _]} <- row do
          if p == Enum.at(path, row_index) do
            "\e[31mx"
          else
            "\e[32mo"
          end
        end)
          |> Enum.join(" ")
          |> IO.puts
      end)
  end
end

ExUnit.start

defmodule TreeTest do
  use ExUnit.Case

  @path Path.expand("support/tree.txt", __DIR__)

  test "read file" do
    tree = Tree.from_file(@path)
    assert length(tree) == 100
    assert Enum.at(tree, 99) == [{59, [0]}]
  end

  test "append index" do
    assert Tree.append_index([1, 2, 3]) == [{1, [0]}, {2, [1]}, {3, [2]}]
  end

  test "pairs" do
    row1 = [{2, [0]}, {4, [1]}, {6, [2]}]
    row2 = [{8, [0]}, {5, [1]}, {9, [2]}, {3, [3]}]
    assert Tree.pairs(row2, row1) == [
      {{2, [0]}, {8, [0]}, {5, [1]}},
      {{4, [1]}, {5, [1]}, {9, [2]}},
      {{6, [2]}, {9, [2]}, {3, [3]}},
    ]
  end

  test "reduce row" do
    row1 = [{30, [0]}, {11, [1]}, {85, [2]}, {31, [3]}, {34, [4]}, {71, [5]}, {13, [6]}, {48, [7]}, {05, [8]}, {14, [9]}, {44, [10]}, {03, [11]}, {19, [12]}, {67, [13]}, {23, [14]}]
    row2 = [{23, [0]}, {33, [1]}, {44, [2]}, {81, [3]}, {80, [4]}, {92, [5]}, {93, [6]}, {75, [7]}, {94, [8]}, {88, [9]}, {23, [10]}, {61, [11]}, {39, [12]}, {76, [13]}, {22, [14]}, {03, [15]}]
    assert Tree.reduce_row(row2, row1) == [
      {63,  [ 0,  1]},
      {55,  [ 1,  2]},
      {166, [ 2,  3]},
      {112, [ 3,  3]},
      {126, [ 4,  5]},
      {164, [ 5,  6]},
      {106, [ 6,  6]},
      {142, [ 7,  8]},
      {99,  [ 8,  8]},
      {102, [ 9,  9]},
      {105, [10, 11]},
      {64,  [11, 11]},
      {95,  [12, 13]},
      {143, [13, 13]},
      {45,  [14, 14]},
    ]
  end

  test "maximal path" do
    tree = Tree.from_file(@path)
    {sum, path} = Tree.maximal_path(tree)
    assert sum == 7273
    assert path == [0, 0, 0, 1, 2, 3, 4, 4, 5, 5, 6, 6, 7, 8, 9, 10, 11, 12, 12, 12, 13, 13, 13, 14, 14, 15, 15, 16, 17, 17, 17, 18, 19, 20, 21, 22, 23, 24, 25, 25, 25, 26, 27, 27, 28, 29, 30, 31, 32, 32, 32, 32, 33, 33, 34, 35, 36, 36, 36, 36, 36, 36, 36, 37, 38, 39, 40, 41, 41, 42, 42, 42, 42, 42, 42, 42, 43, 43, 43, 44, 45, 45, 45, 45, 45, 45, 46, 46, 46, 46, 47, 47, 48, 49, 49, 50, 51, 52, 52, 53]
  end

  def path, do: @path
end

Tree.pretty_print(TreeTest.path)
