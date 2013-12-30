# WIP - not finished yet!

defmodule WebServer do

  def run do
    :inets.start()
    {:ok, pid} = :inets.start :httpd, [
      port: 3000,
      server_name: 'httpd_test',
      server_root: '/tmp',
      document_root: '/home/tim',
      bind_address: {127, 0, 0, 1}
    ]
    wait # still learning how to wait for process (use a Supervisor or Application behavior maybe?)
         # will use this for now
  end

  def wait do
    receive do
      {:DOWN, _, _, _, _} -> :quit
    end
  end
end

WebServer.run
