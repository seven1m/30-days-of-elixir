# A micro web DSL library called "Frank"
# The motivation was mainly to learn about macros.
# One big bummer is that the way I implemented the macro,
# there is no way to build a route based on a regex,
# which is essential for a web DSL. :-)
# Next version will hopefully support regex paths.

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

    $ iex 26-frank.exs

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

  defmacro __using__(_opts) do
    quote do
      import Frank.Path

      def unquote(:do)(data) do
        name = List.to_atom(Frank.mod(data, :request_uri))
        funs = __MODULE__.__info__(:functions)
        if Keyword.get(funs, name) == 1 do
          fun = :erlang.make_fun(__MODULE__, name, 1)
          fun.(data)
        else
          response(404, 'not defined')
        end
      end
    end
  end

  defmodule Path do
    defmacro get(path, contents) do
      contents = Macro.escape(Keyword.get(contents, :do), unquote: true)
      quote bind_quoted: binding do
        def unquote(String.to_atom(path))(data) do
          unquote(contents)
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
