defmodule Martcache.Router do
  use Plug.Router
  require Logger
  plug(Plug.Logger)
  plug(:match)
  plug(:dispatch)

  get "/" do
    send_resp(conn, 200, "Hello, World!")
  end

  get "/pluto/zix" do
    send_resp(conn, 201, "Pluto")
  end

  get "/pluto/:area/*other" do
    # /pluto/anna/bella/zebra.jsp
    # %{"area" => "anna", "other" => ["bella", "zebra.jsp"]}
    %{params: p} = conn
    Logger.error(inspect(p))
    send_resp(conn, 200, "Pluto")
  end

  match _ do
    Logger.error("404 baby")
    send_resp(conn, 404, "not found")
  end
end
