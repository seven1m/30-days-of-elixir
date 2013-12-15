# http://benjamintanweihao.github.io/blog/2013/06/25/elixir-for-the-lazy-impatient-and-busy-part-2-processes-101/
# http://benjamintanweihao.github.io/blog/2013/07/13/elixir-for-the-lazy-impatient-and-busy-part-4-processes-101/

# The goal here was to learn about Elixir's (Erlang's) lightweight processes.
# The following module gets spawned a couple times and ping/pong back and forth.

defmodule Pinger do
  def ping(echo) do
    receive do
      :ok -> :ok
      {sender, _, count} when count > 5 ->
        sender <- :ok
      {sender, msg, count} ->
        IO.puts "Foo Received: #{inspect msg} (count #{count})"
        :timer.sleep(1000)
        sender <- {self, echo, count+1}
        ping(echo)
    end
  end
end

defmodule Spawner do
  def start do
    {foo, _foo_monitor} = Process.spawn_monitor(Pinger, :ping, ["ping"])
    {bar, _bar_monitor} = Process.spawn_monitor(Pinger, :ping, ["pong"])
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
