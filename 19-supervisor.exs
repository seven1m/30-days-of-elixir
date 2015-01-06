# The goal here is to learn (a tiny bit) about the Supervisor
# We simply fire up the server from exercise 18 and restart it on failure.

Code.load_file("./18-gen_server.exs")

defmodule PrimeFactorsServer.Sup do
  use Supervisor

  def start_link do
    :supervisor.start_link(__MODULE__, [])
  end

  def init(_opts) do
    tree = [ worker(PrimeFactorsServer, []) ]
    supervise(tree, strategy: :one_for_one)
  end
end


# to use:
# iex 19-supervisor.exs
# iex> {:ok, pid} = PrimeFactorsServer.Sup.start_link
#
# iex> :gen_server.call(:prime_factors, 100)
# [5, 5, 2, 2]
#
# iex> :gen_server.call(:prime_factors, "a")
# =ERROR REPORT==== 30-Dec-2013::22:54:42 ===
# ** Generic server prime_factors terminating
# ** Last message in was <<"a">>
# ** When Server state == []
# ** Reason for termination ==
# ** {badarg,
# ...
# ** (exit) {{:badarg, [{:math, :sqrt, ["a"], []}, {PrimeFactors, :prime?, 1, [file: '/tim/pp/30-days-of-elixir/18-gen_server.exs', line: 16]}, {PrimeFactors, :prime_factors, 3, [file: '/tim/pp/30-days-of-elixir/18-gen_server.exs', line: 4]}, {PrimeFactorsServer, :handle_call, 3, [file: '/tim/pp/30-days-of-elixir/18-gen_server.exs', line: 49]}, {:gen_server, :handle_msg, 5, [file: 'gen_server.erl', line: 585]}, {:proc_lib, :init_p_do_apply, 3, [file: 'proc_lib.erl', line: 239]}]}, {:gen_server, :call, [:prime_factors, "a"]}}
#     gen_server.erl:180: :gen_server.call/2
#
# iex> :gen_server.call(:prime_factors, 8)
# [2, 2, 2]
