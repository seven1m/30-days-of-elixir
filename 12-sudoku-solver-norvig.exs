defmodule SudokuSolver do
  @moduledoc """
  Solves 9x9 Sudoku puzzles, Peter Norvig style.

  http://norvig.com/sudoku.html

  This is pretty much a straight port of Peter's original Python code,
  so it's not necessarily very idiomatic Elixir I'm afraid.

  Also, it's horribly inefficient compared to the Python version, since
  it doesn't memoize any of the base data structures. (It takes 30 seconds
  on my machine to solve the "hard" puzzle whereas the Python version can
  do it in under a second.)

  I may come back and optimize this at some point if I get ambitious.
  """

  @size 9
  @rows 'ABCDEFGHI'
  @cols '123456789'

  import Enum

  def cross(list_a, list_b) do
    lc a inlist list_a, b inlist list_b, do: [a] ++ [b]
  end

  @doc "Return all squares"
  def squares, do: cross(@rows, @cols)

  @doc """
  All squares divided by row, column, and box.
  """
  def unit_list do
    (lc c inlist @cols, do: cross(@rows, [c])) ++
    (lc r inlist @rows, do: cross([r], @cols)) ++
    (lc rs inlist chunk(@rows, 3), cs inlist chunk(@cols, 3), do: cross(rs, cs))
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
    HashDict.new(
      lc s inlist squares, do: {s, (lc u inlist ul, s in u, do: u)}
    )
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
    HashDict.new(
      lc s inlist squares do
        all = u |> Dict.get(s) |> concat |> HashSet.new
        me = [s] |> HashSet.new
        {s, HashSet.difference(all, me)}
      end
    )
  end

  @doc """
  Convert grid to a Dict of possible values, {square: digits}, or
  return false if a contradiction is detected.
  """
  def parse_grid(grid) do
    # To start, every square can be any digit; then assign values from the grid.
    values = HashDict.new(lc s inlist squares, do: {s, @cols})
    _parse_grid(values, Dict.to_list(grid_values(grid)))
  end

  defp _parse_grid(values, [{square, value} | rest]) do
    values = _parse_grid(values, rest)
    if value in '0.' do
      values
    else
      assign(values, square, value)
    end
  end
  defp _parse_grid(values, []), do: values

  @doc """
  Convert grid into a Dict of {square: char} with '0' or '.' for empties.
  """
  def grid_values(grid) do
    chars = lc c inlist grid, c in @cols or c in '0.', do: c
    unless count(chars) == 81, do: raise('error')
    HashDict.new(zip(squares, chars))
  end

  @doc """
  Eliminate all the other values (except d) from values[s] and propagate.
  Return values, except return false if a contradiction is detected.
  """
  def assign(values, s, d) do
    values = Dict.put(values, s, [d])
    p = Dict.to_list(Dict.get(peers, s))
    eliminate(values, p, [d])
  end

  @doc """
  Eliminate d from values[s]; propagate when values or places <= 2.
  Return values, except return false if a contradiction is detected.
  """
  def eliminate(values, [], _), do: values
  def eliminate(values, [square | rest_squares], vals_to_remove) do
    vals = Dict.get(values, square)
    if Set.intersection(HashSet.new(vals), HashSet.new(vals_to_remove)) |> any? do
      vals = _eliminate(vals, square, vals_to_remove)
      values = Dict.put(values, square, vals)
      # (1) If a square s is reduced to one value, then eliminate it from the peers.
      values = cond do
        count(vals) == 0 -> false # contradiction: removed last value
        count(vals) == 1 -> eliminate(values, Dict.to_list(Dict.get(peers, square)), vals)
        true -> values
      end
      # (2) If a unit u is reduced to only one place for a value d, then put it there.
      values = eliminate_vals_from_units(values, Dict.get(units, square), vals_to_remove)
    end
    values && eliminate(values, rest_squares, vals_to_remove)
  end

  defp _eliminate(vals, square, [val | rest]) do
    vals = List.delete(vals, val)
    _eliminate(vals, square, rest)
  end
  defp _eliminate(vals, _, []), do: vals

  # FIXME eliminate_vals_from_units/3 and eliminate_from_unit/3 would be a pretty simple
  # nested for loop in any OO language. If it weren't for the needed behavior of short-circuiting
  # when we fail to apply a solution, this could be a pretty simple list comprehension. :-(
  # Probably there is some higher-order function I could build to simplify this, but the
  # solution isn't clear to this Functional Programming noob.
  defp eliminate_vals_from_units(false, _, _), do: false
  defp eliminate_vals_from_units(values, [unit | rest_units], vals_to_remove) do
    values = eliminate_from_unit(values, unit, vals_to_remove)
    eliminate_vals_from_units(values, rest_units, vals_to_remove)
  end
  defp eliminate_vals_from_units(values, [], _), do: values

  defp eliminate_from_unit(false, _, _), do: false
  defp eliminate_from_unit(values, unit, [val | rest]) do
    dplaces = lc s inlist unit, val in Dict.get(values, s), do: s
    values = cond do
      empty?(dplaces) ->
        false # contradiction: no place for this value
      count(dplaces) == 1 ->
        # d can only be in one place in unit; assign it there
        assign(values, at(dplaces, 0), val)
      true ->
        values
    end
    eliminate_from_unit(values, unit, rest)
  end
  defp eliminate_from_unit(values, _, []), do: values

  @doc """
  Given a puzzle char list, find the solution and return as a char list.

  Use display/1 to print the grid as a square.
  """
  def solve(grid) do
    grid
      |> parse_grid
      |> search
      |> flatten
  end

  @doc """
  Flatten a values Dict back into a single char list.
  """
  def flatten(values) do
    squares
      |> map(fn s -> Dict.get(values, s) end)
      |> concat
  end

  @doc """
  Using depth-first search and propagation, try all possible values.
  """
  def search(false), do: false
  def search(values) do
    if all?(squares, fn s -> count(Dict.get(values, s)) == 1 end) do
      values # solved!
    else
      # Chose the unfilled square s with the fewest possibilities
      {square, _count} = map(squares, &({&1, count(Dict.get(values, &1))}))
        |> filter(fn {_, c} -> c > 1 end)
        |> sort(fn {_, c1}, {_, c2} -> c1 < c2 end)
        |> first
      find_value Dict.get(values, square), fn d ->
        assign(values, square, d) |> search
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

  test "parse_grid" do
    grid1 = '003020600900305001001806400008102900700000008006708200002609500800203009005010300'
    assert Dict.get(parse_grid(grid1), 'A1') == '4'
    assert Dict.get(parse_grid(grid1), 'A3') == '3'
  end

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
