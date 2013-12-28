defmodule PrimeFactors do
  def prime_factors(number, div // 2, factors // []) do
    cond do
      prime?(number) ->
        [number | factors]
      rem(number, div) == 0 ->
        prime_factors(div(number, div), 2, [div | factors])
      true ->
        prime_factors(number, div + 1, factors)
    end
  end

  def prime?(2), do: true

  def prime?(number) do
    prime?(number, :math.sqrt(number) |> :erlang.trunc)
  end

  defp prime?(_, 1), do: true
  defp prime?(number, div) do
    if rem(number, div) == 0 do
      false
    else
      prime?(number, div - 1)
    end
  end
end

defmodule PrimeFactorsServer do
  use GenServer.Behaviour

  import PrimeFactors

  def init(_args) do
    {:ok, []}
  end

  # synchronous

  def handle_call(:flush, _from, context) do
    {:reply, context, []}
  end

  def handle_call(num, _from, context) do
    {:reply, prime_factors(num), context}
  end

  # asynchronous

  def handle_cast(num, context) do
    {:noreply, [{num, prime_factors(num)} | context]}
  end
end

ExUnit.start

defmodule PrimeFactorsTest do
  use ExUnit.Case

  import PrimeFactors

  test "prime_factors" do
    assert prime_factors(10) == [5, 2]
    assert prime_factors(100) == [5, 5, 2, 2]
  end

  test "prime?" do
    assert(prime?(2))
    assert(prime?(11))
    assert(not prime?(8))
  end

  test "async" do
    {:ok, pid} = :gen_server.start_link(PrimeFactorsServer, [], [])
    :gen_server.cast(pid, 10)
    :gen_server.cast(pid, 100)
    :gen_server.cast(pid, 1000)
    assert :gen_server.call(pid, :flush) == [
      {1000, [5, 5, 5, 2, 2, 2]},
      {100, [5, 5, 2, 2]},
      {10, [5, 2]}
    ]
    assert :gen_server.call(pid, :flush) == []
  end
end

