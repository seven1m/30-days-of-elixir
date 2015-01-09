# A micro web DSL library called "Frank"
# The motivation was mainly to learn about macros.
#
# This version is only slightly better than the last...
# It still does not support paths with regex match :-(
#
# Improvements over the last version are:
# * define methods as `def handle(path, data)` instead of `def path(data)`
# * used @before_compile callback to set a default handler method

require Record

defmodule Frank do
  @moduledoc """
    Frank is a micro web library that provides a DSL for defining routes.

        defmodule MyApp do
          use Frank

          get "/foo" do
            response 200, "foo!"
          end
        end

        Frank.sing(MyApp)

    To run:

    $ iex 27-frank-2.exs

    ... then point your browser to http://localhost:3000
  """

  Record.defrecord :mod, Record.extract(:mod, from_lib: "inets/include/httpd.hrl")

  @doc """
    Start the web server given the app module.
  """
  def sing(module) do
    :inets.start()
    options = [server_name: 'frank', server_root: '/tmp', document_root: '/tmp', port: 3000, modules: [module]]
    {:ok, _pid} = :inets.start :httpd, options
    IO.puts "running on port 3000"
  end

  defmodule Path do
    defmacro get(path, contents) do
      contents = Macro.escape(Keyword.get(contents, :do))
      quote bind_quoted: binding do
        def handle(unquote(path), data) do
          unquote(contents)
        end
      end
    end

    defmacro __before_compile__(_env) do
      quote do
        def handle(_, data) do
          IO.puts 'here default!'
          response(404, 'not defined')
        end
      end
    end

    def redirect(path, code \\ 302) do
      body = ['redirecting you to <a href="', path, '">', path, '</a>']
      response code, body, [location: path]
    end

    def sanitize(content) do
      content = Regex.replace(~r/&/, content, "\\&amp;")
      content = Regex.replace(~r/</, content, "\\&lt;")
      content = Regex.replace(~r/>/, content, "\\&gt;")
      content
    end

    def response(code, body, headers \\ []) do
      if is_binary(body) do
        body = :erlang.bitstring_to_list(body)
      end
      headers = [code: code, content_length: Integer.to_char_list(IO.iodata_length(body))] ++ headers
      {:proceed, [response: {:response, headers, body}]}
    end
  end

  defmacro __using__(_opts) do
    quote do
      import Frank.Path

      def unquote(:do)(data) do
        name = Frank.mod(data, :request_uri)
        IO.puts "calling #{name}"
        handle(:erlang.list_to_bitstring(name), data)
      end

      @before_compile Path
    end
  end
end

defmodule Test do
  use Frank

  get "/" do
    response 200, "<a href='/foo'>go to foo</a>"
  end

  get "/foo" do
    response 200, "foo!"
  end
end

Frank.sing(Test)
