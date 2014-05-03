# Just playing with some digest stuff.
#
# To run:
#
# $ erlc support/sha1.erl && mv sha1.beam support/
# $ elixir 23-digest.exs
#
# Observations:
#
# * Erlang/Elixir don't have a sha1 method built-in???
# * Erlang/Elixir don't have a built-in binary-to-hex conversion???
# * Loading Erlang code was a bit weird. I should have figured out
#   how to compile erl files within the code (not the terminal)
#
# Dude, where's my expansive standard library?!

:code.load_abs('support/sha1')

ExUnit.start

defmodule MiscTest do
  use ExUnit.Case

  test "sha1" do
    # Erlang doesn't have sha1 built-in, so had to import code from
    # our friend Mr. Nicolas Favre-Felix
    assert :sha1.hexstring('foo') == '0BEEC7B5EA3F0FDBC95D0DD47F3C5BC275DA8A33'
  end

  test "md5" do
    # Erlang has crypto built-in for md5, but no way natively to convert to hex
    # so again Mr. Felix to the rescue!
    assert :crypto.hash(:md5, 'foo') |> :sha1.bin2hex == 'ACBD18DB4CC2F85CEDEF654FCCC4A4D8'
  end
end
