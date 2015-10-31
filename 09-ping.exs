# If you get errors running 254 ping commands it's probably due to the number
# of open files.  You can "fix" this by running this command in the terminal
# session before running this program:
#
#   ulimit -n 1024
#
# If the limit is 256 (the default) then we can run 120 or so before we run out
# of file descriptors.

defmodule Ping do
  @moduledoc """
  Ping a class-C subnet to find hosts that respond.
  To run from the command line:

    $ elixir 09-ping.exs 192.168.1.x
  """

  @doc """
  Ping an IP asynchronously and send a tuple back to the parent saying what
  has happened:

  `{:ok, ip, pingable?}` where `pingable?` tells us if `ip` is pingable.

  `{:error, ip, error}` when some error caused us to not be able to run the
  ping command.

  """
  def ping_async(ip, parent) do
    send parent, run_ping(ip)
  end

  @doc """
  Ping a single IP address returning a tuple which `ping_async` can return.
  """
  def run_ping(ip) do
    # This is a Ruby-ish way of dealing with failure...
    # TODO: Discover the "Elixir way"
    try do
      # return code should be handled somehow with pattern matching
      {cmd_output, _} = System.cmd("ping", ping_args(ip))
      alive? = not Regex.match?(~r/100(\.0)?% packet loss/, cmd_output)
      {:ok, ip, alive?}
    rescue
      e -> {:error, ip, e}
    end
  end

  def ping_args(ip) do
    wait_opt = if darwin?, do: '-W', else: '-w'
    ["-c", "1", wait_opt, "5", "-s", "1", ip]
  end

  def darwin? do
    {output, 0} = System.cmd("uname", [])
    String.rstrip(output) == "Darwin"
  end
end

defmodule Subnet do
  @doc """
  Ping all IPs in a class-C subnet and return a Dict with results.
  """
  def ping(subnet) do
    all = ips(subnet)
    Enum.each all, fn ip ->
      # Task.start gives better logging than spawn when things go awry.
      # http://elixir-lang.org/getting-started/processes.html#tasks
      Task.start(Ping, :ping_async, [ip, self])
    end
    wait HashDict.new, Enum.count(all)
  end

  @doc """
  Given a class-C subnet string like '192.168.1.x', return list of all 254 IPs therein.
  """
  def ips(subnet) do
    subnet = Regex.run(~r/^\d+\.\d+\.\d+\./, subnet) |> Enum.at(0)
    Enum.to_list(1..254) |> Enum.map fn i -> "#{subnet}#{i}" end
  end

  defp wait(dict, 0), do: dict
  defp wait(dict, remaining) do
    receive do
      {:ok, ip, pingable?} ->
        dict = Dict.put(dict, ip, pingable?)
      {:error, ip, error} ->
        IO.puts "#{inspect error} for #{ip}"
    end
    wait dict, remaining - 1
  end
end

# Command-line execution support
# TODO is there a way to check if this script is being executed directly (vs imported elsewhere)?
case System.argv do
  [subnet] ->
    results = Subnet.ping(subnet)
    Enum.filter_map(results, fn {_ip, exists} -> exists end, fn {ip, _} -> ip end)
      |> Enum.sort
      |> Enum.join("\n")
      |> IO.puts
  _ ->
    ExUnit.start

    defmodule SubnetTest do
      use ExUnit.Case

      test "ips" do
        ips = Subnet.ips("192.168.1.x")
        assert Enum.count(ips) == 254
        assert Enum.at(ips, 0) == "192.168.1.1"
        assert Enum.at(ips, 253) == "192.168.1.254"
      end
    end
end
