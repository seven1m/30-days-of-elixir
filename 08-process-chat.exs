# http://benjamintanweihao.github.io/blog/2013/06/25/elixir-for-the-lazy-impatient-and-busy-part-2-processes-101/
# http://benjamintanweihao.github.io/blog/2013/07/13/elixir-for-the-lazy-impatient-and-busy-part-4-processes-101/

# The goal here was to learn about Elixir's (Erlang's) lightweight processes.
# The following two modules get spawned as processes and start ping/ponging to each other.

defmodule Foo do
  def foo do
    receive do
      :ok -> :ok
      {sender, _, count} when count > 5 ->
        sender <- :ok
      {sender, msg, count} ->
        IO.puts "Foo Received: #{inspect msg} (count #{count})"
        :timer.sleep(1000)
        sender <- {self, "ping", count+1}
        foo
    end
  end
end

defmodule Bar do
  def bar do
    receive do
      :ok -> :ok
      {sender, _, count} when count > 5 ->
        sender <- :ok
      {sender, msg, count} ->
        IO.puts "Bar Received: #{inspect msg} (count #{count})"
        :timer.sleep(1000)
        sender <- {self, "pong", count+1}
        bar
    end
  end
end

defmodule Spawner do
  def start do
    {foo, _foo_monitor} = Process.spawn_monitor(Foo, :foo, [])
    {bar, _bar_monitor} = Process.spawn_monitor(Bar, :bar, [])
    foo <- {bar, "start", 0}
    wait [foo, bar]
  end

  @doc "Waits for all processes to finish before exiting."
  def wait(pids) do
    IO.puts "waiting for pids #{inspect pids}"
    receive do
      {:DOWN, _, _, pid, _} ->
        IO.puts "#{inspect pid} quit"
        pids = List.delete(pids, pid)
        unless Enum.empty?(pids) do
          wait(pids)
        end
    end
  end
end

Spawner.start
