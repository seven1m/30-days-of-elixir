# http://elixir-lang.org/docs/stable/Dict.html
# http://elixir-lang.org/docs/stable/HashDict.html
# http://elixir-lang.org/docs/stable/ListDict.html

ExUnit.start

# Keyword and ListDict work fairly interchangeably AFAICT
# except Keyword can only have keys that are atoms
# Dict can have any value as key

defmodule KeywordTest do
  use ExUnit.Case

  def sample do
    [foo: 'bar', baz: 'quz']
  end

  test "get" do
    assert Keyword.get(sample, :foo) == 'bar'
    assert Keyword.get(sample, :non_existent) == nil
  end

  test "put" do
    assert Keyword.put(sample, :foo, 'bob') == [foo: 'bob', baz: 'quz']
    assert Keyword.put(sample, :far, 'bar') == [far: 'bar', foo: 'bar', baz: 'quz']
  end

  test "values" do
    assert Keyword.values(sample) == ['bar', 'quz']
  end
end

defmodule HashDictTest do
  use ExUnit.Case

  def sample do
    HashDict.new(foo: 'bar', baz: 'quz')
  end

  # Dict module seems more like The Future, as it handles all different Dict implementations
  test "get" do
    assert Dict.get(sample, :foo) == 'bar'
    assert Dict.get(sample, :non_existent) == nil
  end

  test "fetch" do
    {:ok, val} = Dict.fetch(sample, :foo)
    assert val == 'bar'
    :error = Dict.fetch(sample, :non_existent)
  end

  test "put" do
    assert Dict.put(sample, :foo, 'bob') == HashDict.new(foo: 'bob', baz: 'quz')
    assert Dict.put(sample, :far, 'bar') == HashDict.new(far: 'bar', foo: 'bar', baz: 'quz')
  end

  test "values" do
    # HashDict does not preserve order of keys, thus we Enum.sort
    assert Enum.sort(Dict.values(sample)) == ['bar', 'quz']
  end
end


defmodule SpeedTest do
  use ExUnit.Case

  # ListDict is slow! (866650 microsecs)
  test "ListDict speed" do
    {microsec, _} = :timer.tc fn ->
      Enum.reduce 1..10_000, ListDict.new, fn (i, d) ->
        Dict.put d, i, 'foo'
      end
    end
    IO.puts "ListDict took #{microsec} microsecs"
  end

  # HashDict is faster (11085 microsecs)
  test "HashDict speed" do
    {microsec, _} = :timer.tc fn ->
      Enum.reduce 1..10_000, HashDict.new, fn (i, d) ->
        Dict.put d, i, 'foo'
      end
    end
    IO.puts "HashDict took #{microsec} microsecs"
  end
end

