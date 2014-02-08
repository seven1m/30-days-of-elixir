defmodule SudokuBoard do
  @moduledoc "Functions to interrogate a board."

  import Enum

  @doc "Returns true if the board is solved."
  def solved?(board) do
    rows_solved?(board) and cols_solved?(board)
  end

  @doc "Returns true if all rows are solved."
  def rows_solved?([row | rest]) do
    max = count(row)
    sort(row) == to_list(1..max) and rows_solved?(rest)
  end
  def rows_solved?([]), do: true

  @doc "Returns true if all columns are solved."
  def cols_solved?(board) do
    do_cols_solved?(board, count(board)-1)
  end

  defp do_cols_solved?(board, index) when index >= 0 do
    max = count(board)
    col = map board, fn row -> at(row, index) end
    sort(col) == to_list(1..max) and do_cols_solved?(board, index-1)
  end
  defp do_cols_solved?(_, -1), do: true
end

ExUnit.start

defmodule SudokuBoardTest do
  use ExUnit.Case

  import SudokuBoard

  test "solved? on solved board" do
    board = [
      [1, 2],
      [2, 1]
    ]
    assert solved?(board)
  end

  test "solved? on incorrectly solved board" do
    board = [
      [1, 1],
      [2, 1]
    ]
    assert not solved?(board)
    board = [
      [2, 1],
      [2, 1]
    ]
    assert not solved?(board)
  end
end
