# just playing with inets - nothing special

defmodule WebServer do
  def run do
    :inets.start()
    options = [server_name: 'foo', server_root: '/tmp', document_root: '/tmp', port: 3000, modules: [App]]
    {:ok, _pid} = :inets.start :httpd, options
    receive do: (_ -> :ok) # TODO better way to wait?
  end
end

defmodule App do
  defrecord :mod, Record.extract(:mod, from_lib: "inets/include/httpd.hrl")

  def unquote(:do)(data) do
    response = case data.request_uri do
      '/' -> 'hello world'
      _   -> ['hello ', data.request_uri]
    end
    {:proceed, [response: {200, response}]}
  end
end

WebServer.run
