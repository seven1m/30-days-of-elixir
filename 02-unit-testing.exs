# http://elixir-lang.org/getting_started/ex_unit/1.html

ExUnit.start                                # set up the test runner

defmodule MyTest do
  use ExUnit.Case                           # use requires a module and sets up macros; will explore more later

  def test_assert(_) do                     # method name starting with "test" and accepting one arg
    assert 1 + 1 == 2
    #assert 1 + 1 == 3                      # Elixir is smart! No need for assert_equal, assert_gte, etc.
                                            # And we still get great failure messages, yipee!
                                            # 1) test_assert (MyTest)
                                            #    ** (ExUnit.ExpectationError)
                                            #                 expected: 2
                                            #      to be equal to (==): 3
  end

  test "refute is opposite of assert" do    # test macro accepts string as test name
    refute 1 + 1 == 3
  end

  test :assert_raise do                     # test macro also accepts an atom
    assert_raise ArithmeticError, fn ->
      1 + "x"
    end
  end

  test "assert_in_delta" do
    assert_in_delta 1, # actual
                    5, # expected
                    6  # delta
  end

end
