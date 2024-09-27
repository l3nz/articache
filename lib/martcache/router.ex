defmodule Martcache.Router do
  use Plug.Router
  require Logger
  alias Martcache.DownloadSrv

  # curl 'http://127.0.0.1:3033/boss/jar/com/google/gwt/gwt-dev/2.9.0/gwt-dev-2.9.0.jar'

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

  get "/boss/:area/*package" do
    %{params: %{"package" => package_parts, "area" => area}} = conn

    file = DownloadSrv.download(area, package_parts)

    case file do
      nil ->
        send_resp(conn, 404, "not found")

      f ->
        with %File.Stat{size: sz} = File.stat!(f) do
          Logger.info("Sending #{f} with size #{sz}")
          send_file(conn, 200, f)
        end
    end
  end

  head "/boss/:area/*package" do
    %{params: %{"package" => package_parts, "area" => area}} = conn

    file = DownloadSrv.download(area, package_parts)
    %File.Stat{size: sz} = File.stat!(file)
    Logger.info("Heading #{file} with size #{sz}")

    send_resp(conn, 200, "Pluto")
  end

  match _ do
    Logger.error("404 baby")
    send_resp(conn, 404, "not found")
  end
end
