defmodule SudokuSolver do
  @moduledoc """
  Solves 9x9 Sudoku puzzles, Peter Norvig style.

  http://norvig.com/sudoku.html
  """

  @size 9
  @rows 'ABCDEFGHI'
  @cols '123456789'

  import Enum

  # used to cache all squares, units, and peer relationships
  defmodule Board do
    defstruct squares: nil, units: nil, peers: nil
  end

  def cross(list_a, list_b) do
    for a <- list_a, b <- list_b, do: [a] ++ [b]
  end

  @doc "Return all squares"
  def squares, do: cross(@rows, @cols)

  @doc """
  All squares divided by row, column, and box.
  """
  def unit_list do
    (for c <- @cols, do: cross(@rows, [c])) ++
    (for r <- @rows, do: cross([r], @cols)) ++
    (for rs <- chunk(@rows, 3), cs <- chunk(@cols, 3), do: cross(rs, cs))
  end

  @doc """
  All squares from unit_list, organized in a Dict with each square as key.

     iex> Dict.get(SudokuSolver.units, 'C2')
     [['A2', 'B2', 'C2', 'D2', 'E2', 'F2', 'G2', 'H2', 'I2'],
      ['C1', 'C2', 'C3', 'C4', 'C5', 'C6', 'C7', 'C8', 'C9'],
      ['A1', 'A2', 'A3', 'B1', 'B2', 'B3', 'C1', 'C2', 'C3']]
  """
  def units do
    ul = unit_list
    list = for s <- squares, do: {s, (for u <- ul, s in u, do: u)}
    Enum.into(list, HashDict.new)
  end

  @doc """
  Like units/0 above, returning a Dict, but not including the key itself.

     iex> Dict.get(SudokuSolver.peers, 'C2')
     HashSet.new(['A2', 'B2', 'D2', 'E2', 'F2', 'G2', 'H2', 'I2',
                  'C1', 'C3', 'C4', 'C5', 'C6', 'C7', 'C8', 'C9',
                  'A1', 'A3', 'B1', 'B3'])
  """
  def peers do
    squares = cross(@rows, @cols)
    u = units
    list = for s <- squares do
      all = u |> Dict.get(s) |> concat |> Enum.into(HashSet.new)
      me = [s] |> Enum.into(HashSet.new)
      {s, HashSet.difference(all, me)}
    end
    Enum.into(list, HashDict.new)
  end

  @doc """
  Convert grid to a Dict of possible values, {square: digits}, or
  return false if a contradiction is detected.
  """
  def parse_grid(grid, board) do
    # To start, every square can be any digit; then assign values from the grid.
    values = Enum.into((for s <- board.squares, do: {s, @cols}), HashDict.new)
    do_parse_grid(values, Dict.to_list(grid_values(grid)), board)
  end

  defp do_parse_grid(values, [{square, value} | rest], board) do
    values = do_parse_grid(values, rest, board)
    if value in '0.' do
      values
    else
      assign(values, square, value, board)
    end
  end
  defp do_parse_grid(values, [], _), do: values

  @doc """
  Convert grid into a Dict of {square: char} with '0' or '.' for empties.
  """
  def grid_values(grid) do
    chars = for c <- grid, c in @cols or c in '0.', do: c
    unless count(chars) == 81, do: raise('error')
    Enum.into(zip(squares, chars), HashDict.new)
  end

  @doc """
  Eliminate all the other values (except d) from values[s] and propagate.
  Return values, except return false if a contradiction is detected.
  """
  def assign(values, s, d, board) do
    values = Dict.put(values, s, [d])
    p = Dict.to_list(Dict.get(board.peers, s))
    eliminate(values, p, [d], board)
  end

  @doc """
  Eliminate values from given squares and propagate.
  """
  def eliminate(values, squares, vals_to_remove, board) do
    reduce_if_truthy squares, values, fn square, values ->
      eliminate_vals_from_square(values, square, vals_to_remove, board)
    end
  end

  # Remove value(s) from a square, then:
  # (1) If a square s is reduced to one value, then eliminate it from the peers.
  # (2) If a unit u is reduced to only one place for a value d, then put it there.
  defp eliminate_vals_from_square(values, square, vals_to_remove, board) do
    vals = Dict.get(values, square)
    if Set.intersection(Enum.into(vals, HashSet.new), Enum.into(vals_to_remove, HashSet.new)) |> any? do
      vals = reduce vals_to_remove, vals, fn val, vals -> List.delete(vals, val) end
      if length(vals) == 0 do
        # contradiction, removed last value
        false
      else
        values = Dict.put(values, square, vals)
        values = if length(vals) == 1 do
          # eliminate value(s) from the peers.
          eliminate(values, Dict.to_list(Dict.get(board.peers, square)), vals, board)
        else
          values
        end
        # eliminate value(s) from units
        eliminate_from_units(values, Dict.get(board.units, square), vals_to_remove, board)
      end
    else
      values
    end
  end

  # If a unit u is reduced to only one place for a value d, then put it there.
  defp eliminate_from_units(values, units, vals_to_remove, board) do
    reduce_if_truthy units, values, fn unit, values ->
      reduce_if_truthy vals_to_remove, values, fn val, values ->
        dplaces = for s <- unit, val in Dict.get(values, s), do: s
        case length(dplaces) do
          0 -> false                                      # contradiction: no place for this value
          1 -> assign(values, at(dplaces, 0), val, board) # d can only be in one place in unit; assign it there
          _ -> values
        end
      end
    end
  end

  # Similar to Enum.reduce/3 except it won't continue to call the work function
  # if the accumulator becomes false or nil.
  defp reduce_if_truthy(coll, acc, fun) do
    reduce coll, acc, fn i, a ->
      a && fun.(i, a)
    end
  end

  @doc """
  Given a puzzle char list, find the solution and return as a char list.

  Use display/1 to print the grid as a square.
  """
  def solve(grid) do
    board = %Board{squares: squares, units: units, peers: peers}
    grid
      |> parse_grid(board)
      |> search(board)
      |> flatten(board)
  end

  @doc """
  Flatten a values Dict back into a single char list.
  """
  def flatten(values, board) do
    board.squares
      |> map(fn s -> Dict.get(values, s) end)
      |> concat
  end

  @doc """
  Using depth-first search and propagation, try all possible values.
  """
  def search(false, _), do: false
  def search(values, board) do
    if all?(board.squares, fn s -> count(Dict.get(values, s)) == 1 end) do
      values # solved!
    else
      # Chose the unfilled square s with the fewest possibilities
      {square, _count} = map(board.squares, &({&1, count(Dict.get(values, &1))}))
        |> filter(fn {_, c} -> c > 1 end)
        |> sort(fn {_, c1}, {_, c2} -> c1 < c2 end)
        |> List.first
      find_value Dict.get(values, square), fn d ->
        assign(values, square, d, board) |> search(board)
      end
    end
  end

  @doc """
  Display these values as a 2-D grid.
  """
  def display(grid) do
    chunk(grid, @size)
      |> map(fn row -> chunk(row, 1) |> join(" ") end)
      |> join("\n")
      |> IO.puts
  end
end

ExUnit.start

defmodule SudokuSolverTest do
  use ExUnit.Case

  import SudokuSolver

  def print(grid, solved) do
    IO.puts "puzzle-----------"
    display(grid)
    IO.puts "solved-----------"
    display(solved)
    IO.puts "\n"
  end

  test "solve easy" do
    grid1 = '..3.2.6..9..3.5..1..18.64....81.29..7.......8..67.82....26.95..8..2.3..9..5.1.3..'
    solved = solve(grid1)
    assert solved == '483921657967345821251876493548132976729564138136798245372689514814253769695417382'
    print(grid1, solved)
  end

  test "solve hard" do
    grid2 = '4.....8.5.3..........7......2.....6.....8.4......1.......6.3.7.5..2.....1.4......'
    solved = solve(grid2)
    assert solved == '417369825632158947958724316825437169791586432346912758289643571573291684164875293'
    print(grid2, solved)
  end
end
