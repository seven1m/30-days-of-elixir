require IEx
require Record

defmodule Wiki do
  @moduledoc """
    A very simple wiki.
    CamelCase words are auto-linked.
    Pages are stored in the support/wiki directory.

    To run:

    $ iex 21-wiki.exs

    ... then point your browser to http://localhost:3000
  """

  Record.defrecord :mod, Record.extract(:mod, from_lib: "inets/include/httpd.hrl")

  @page_name "([A-Z][a-z0-9]+){2,}"
  @valid_page_name ~r/^([A-Z][a-z0-9]+){2,}$/
  @edit_path ~r/^([A-Z][a-z0-9]+){2,}\/edit$/

  @doc """
    Start the inets server.
  """
  def run do
    :inets.start()
    options = [server_name: 'foo', server_root: '/tmp', document_root: '/tmp', port: 3000, modules: [__MODULE__]]
    {:ok, _pid} = :inets.start :httpd, options
    IO.puts "running on port 3000"
  end

  def unquote(:do)(data) do
    [_slash | name] = mod(data, :request_uri)

    cond do
      name == '' ->
        redirect('/HomePage')
      Regex.match?(@valid_page_name, :erlang.list_to_bitstring(name)) ->
        case mod(data, :method) do
          'GET'  -> render_page(name)
          'POST' -> save_page(name, data); redirect(name)
        end
      Regex.match?(@edit_path, :erlang.list_to_bitstring(name)) ->
        name = Regex.replace(~r/\/edit$/, :erlang.list_to_bitstring(name), "")
        render_page(name, :edit)
      true ->
        response(404, 'bad path')
    end
  end

  def redirect(path, code \\ 302) do
    body = ['redirecting you to <a href="', path, '">', path, '</a>']
    response code, body, [location: path]
  end

  def render_page(name, action \\ :show) do
    case {action, File.read(page_path(name))} do
      {:edit, {:ok, body}} ->
        response 200, edit_page_form(name, body) |> :erlang.bitstring_to_list
      {:show, {:ok, body}} ->
        response 200, body |> format(name) |> :erlang.bitstring_to_list
      _ ->
        response 404, edit_page_form(name) |> :erlang.bitstring_to_list
    end
  end

  def format(content, name) do
    content
      |> sanitize
      |> breakify
      |> linkify
      |> layoutify(name)
  end

  def sanitize(content) do
    content = Regex.replace(~r/&/, content, "\\&amp;")
    content = Regex.replace(~r/</, content, "\\&lt;")
    content = Regex.replace(~r/>/, content, "\\&gt;")
    content
  end

  def breakify(content) do
    Regex.replace(~r/\r?\n/, content, "<br>")
  end

  def linkify(content) do
    {:ok, regex} = Regex.compile(@page_name)
    Regex.replace(regex, content, "<a href='/\\0'>\\0</a>")
  end

  def layoutify(content, name) do
    """
      <style>nav { margin-bottom: 25px; }</style>
      <nav><a href='/HomePage'>HomePage</a> | <a href='/#{name}/edit'>edit</a></nav>
      <section>#{content}</section>
    """
  end

  def page_path(name) do
    Path.join("support/wiki", name) |> Path.expand(__DIR__)
  end

  def save_page(name, data) do
    [{'content', content}] = :httpd.parse_query(mod(data, :entity_body))
    File.write!(page_path(name), content)
  end

  def edit_page_form(name, content \\ "") do
    "<form action='/#{name}' method='post'><textarea name='content' rows='25' cols='80'>#{content}</textarea><br><button>Save</button><a href='/#{name}'>cancel</a></form>"
  end

  def response(code, body, headers \\ []) do
    headers = [code: code, content_length: Integer.to_char_list(IO.iodata_length(body))] ++ headers
    {:proceed, [response: {:response, headers, body}]}
  end
end

Wiki.run
