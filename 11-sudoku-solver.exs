Code.load_file("./10-sudoku-board.exs")

defmodule SudokuSolver do
  @moduledoc """
  Brute force solve a Sudoku puzzle.

  TODO this is not a feasible approach for a 9x9 board since it generates too many combinations.
  I will be working on a better solution soon.

  This module does not concern itself with input/output -- it's up to you to feed
  it a list of lists that represents the board, where `nil` is used to indicate a blank.

  Here is a very small board to be solved:

    iex> board = [[1,   nil, 3  ],
                  [3,   nil, 2  ],
                  [nil, 3,   nil]]

  The solve/1 method accepts the board and returns it solved:

    iex> SudokuSolver.solve(board)
    [[1, 2, 3],
     [3, 1, 2],
     [2, 3, 1]]

  The way it works is by first determining possible solutions. Each solution is determined
  by first building a list of non-used numbers for each row, e.g. in the sample board
  above, the missing number in the first row is 2, second row is 1, and third row is 1 and 2.

  Then, these "possibles" are combined to find possible solutions. For the sample board above,
  possible solutions are: [2, 1, 1, 2] and [2, 1, 2, 1].

  From there, we simply brute force check each solution against the board to see if it's solved.

  In effect, we are using logic to find possible solutions that work for each *row*, then we
  use brute force to check the solutions against each *column*.
  """

  import Enum

  @doc """
  Given a list of lists (a square) containing some numbers (which represents a Sudoku board),
  and containing nils where blanks are, return a square with all numbers filled in.

  ## Example

    iex> board = [[1,   nil, 3  ],
                  [3,   nil, 2  ],
                  [nil, 3,   nil]]
    iex> SudokuSolver.solve(board)
    [[1, 2, 3],
     [3, 1, 2],
     [2, 3, 1]]
  """
  def solve(board) do
    board
      |> solutions
      |> map(fn s -> apply_solution(board, s) end)
      |> find(fn b -> SudokuBoard.solved?(b) end)
  end

  @doc """
  Given a board and a solution, insert the values from the solution
  into the nil spots in the board.

  TODO I'm not happy with how this method turned out.
  It seems inefficient to flatten and reconstitute the board on each iteration.

  ## Example

    iex> board = [[1,   nil],
                  [nil, 1  ]]
    iex> SudokuSolver.apply_solution(board, [2, 2])
    [[1, 2], [2, 1]]
  """
  def apply_solution(board, [first | rest]) do
    size = count(board)
    board = List.flatten(board)
    pos = find_index board, fn col -> col == nil end
    List.replace_at(board, pos, first)
      |> chunk(size)
      |> apply_solution(rest)
  end
  def apply_solution(board, []), do: board

  @doc """
  Returns possible combinations for solving the board.

  ## Example

    iex> board = [[1,   nil, 3  ],
                  [3,   nil, 2  ],
                  [nil, 3,   nil]]
    iex> SudokuSolver.solutions(board)
    [[2, 1, 1, 2], [2, 1, 2, 1]]
  """
  def solutions(board) do
    possibles(board) |> combinations
  end

  defp possibles([row | rest]) do
    possible = to_list(1..count(row)) -- row
    [possible | possibles(rest)]
  end
  defp possibles([]), do: []

  @doc """
  Given a list of possibilities for each row, return all possible combinations.

  ## Example

    iex> SudokuSolver.combinations([[1], [2], [3, 4]])
    [[1, 2, 3, 4], [1, 2, 4, 3]]
  """
  def combinations([list | rest]) do
    crest = combinations(rest)
    for p <- permutations(list), r <- crest do
      List.flatten([p | r])
    end
  end
  def combinations([]), do: [[]]

  @doc """
  Return all possible permuations of a list.

  ## Example

    iex> SudokuSolver.permutations([1,2,3])
    [[1,2,3], [1,3,2], [2,1,3], [2,3,1], [3,1,2], [3,2,1]]
  """
  # http://whileonefork.blogspot.com/2010/11/erlang-so-awesome-it-makes-my-brain.html
  def permutations([]), do: [[]]
  def permutations(list) do
    for h <- list, t <- permutations(list -- [h]), do: [h | t]
  end
end

ExUnit.start

defmodule SudokuSolverTest do
  use ExUnit.Case

  import SudokuSolver

  test "correct behavior of combinations" do
    assert combinations([[1]]) == [[1]]
    assert combinations([[2, 3], [1]]) == [[2, 3, 1], [3, 2, 1]]
    assert combinations([[1], [2], [3, 4]]) == [[1, 2, 3, 4], [1, 2, 4, 3]]
  end

  test "solves a small board" do
    board = [[1,   nil, 3  ],
             [3,   nil, 2  ],
             [nil, 3,   nil]]
    assert solve(board) == [[1, 2, 3],
                            [3, 1, 2],
                            [2, 3, 1]]
  end

  test "returns nil on unsolvable board" do
    board = [[1,   nil, 3  ],
             [3,   nil, 2  ],
             [nil, 2,   nil]]
    assert solve(board) == nil
  end

end
