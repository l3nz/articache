defmodule Martcache.Router do
  use Plug.Router
  require Logger
  alias Martcache.DownloadSrv

  # curl 'http://127.0.0.1:3033/boss/com/google/gwt/gwt-dev/2.9.0/gwt-dev-2.9.0.jar'

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

  get "/boss/*package" do
    %{params: %{"package" => package_parts}} = conn

    package = package_parts |> Enum.join("/")

    file = DownloadSrv.download("https://repo1.maven.org/maven2/#{package}")
    %File.Stat{size: sz} = File.stat!(file)

    send_resp(conn, 200, "File: #{file} with size #{sz}")
  end

  match _ do
    Logger.error("404 baby")
    send_resp(conn, 404, "not found")
  end
end
