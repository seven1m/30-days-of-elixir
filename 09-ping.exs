# NOTE: I just recently tried running this on my Mac OS machine.
# Unfortunately, there seems to be a problem spawning 254 `ping` commands. I'm not sure what to do.
# If you want to see this script run on Mac, change line 54 to 1..100 so you can see something happen. :-/

defmodule Ping do
  @moduledoc """
  Ping a class-C subnet to find hosts that respond.
  To run from the command line:

    $ elixir 09-ping.exs 192.168.1.x
  """

  @doc """
  Ping an IP asynchronously and send the {ip, exists} tuple to the parent
  """
  def ping_async(ip, parent) do
    send parent, {ip, ping(ip)}
  end

  @doc """
  Ping a single IP address and return true if there is a response."
  """
  def ping(ip) do
    result = System.cmd(ping_cmd(ip))
    not Regex.match?(~r/100(\.0)?% packet loss/, result)
  end

  def ping_cmd(ip) do
    "ping -c 1 #{if darwin?, do: '-W', else: '-w'} 5 -s 1 #{ip}"
  end

  def darwin? do
    System.cmd("uname") |> String.strip == "Darwin"
  end
end

defmodule Subnet do
  @doc """
  Ping all IPs in a class-C subnet and return a Dict with results.
  """
  def ping(subnet) do
    all = ips(subnet)
    Enum.each all, fn ip ->
      Process.spawn(Ping, :ping_async, [ip, self])
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
      {ip, exists} ->
        dict = Dict.put(dict, ip, exists)
        wait dict, remaining-1
    end
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
