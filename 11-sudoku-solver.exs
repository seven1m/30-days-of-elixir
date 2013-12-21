Code.load_file("./10-sudoku-board.exs")

defmodule SudokuSolver do
  @moduledoc "Brute force solves a Sudoku puzzle."

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
      |> find fn b -> SudokuBoard.solved?(b) end
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
  Returns all possible combinations for solving the board.

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
    lc p inlist permutations(list), r inlist crest do
      flat_map p, fn i -> [i | r] end
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
    lc h inlist list, t inlist permutations(list -- [h]), do: [h | t]
  end
end

ExUnit.start

defmodule SudokuSolverTest do
  use ExUnit.Case

  import SudokuSolver

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


