# just playing with inets - nothing special

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
    receive do: (_ -> :ok) # TODO better way to wait?
  end
end

WebServer.run
