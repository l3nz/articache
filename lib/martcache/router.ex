defmodule Martcache.Router do
  use Plug.Router
  require Logger
  alias Martcache.DownloadSrv

  # curl 'http://127.0.0.1:3033/boss/jar/com/google/gwt/gwt-dev/2.9.0/gwt-dev-2.9.0.jar'

  # per NPM
  # ./localnpm set registry http://127.0.0.1:3033/jar
  # npm set registry https://registry.npmjs.org/
  # ma npm scarica cartelle (?)
  # es /bossyx/get-stream -> https://registry.npmjs.org/get-stream
  # mi crea un grosso json (index.json)

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

  get "/bossyx/:area/*package" do
    %{params: %{"package" => package_parts, "area" => area}} = conn

    Logger.info("GET #{area} #{inspect(package_parts)}")

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

  head "/bossyx/:area/*package" do
    %{params: %{"package" => package_parts, "area" => area}} = conn

    Logger.info("HEAD #{area} #{inspect(package_parts)}")

    case DownloadSrv.download(area, package_parts) do
      f when is_binary(f) ->
        with %File.Stat{size: sz} = File.stat!(f) do
          Logger.info("Heading #{f} with size #{sz}")

          send_resp(conn, 200, "File: #{f}")
        end

      _ ->
        send_resp(conn, 404, "not found")
    end
  end

  match _ do
    Logger.error("404 baby - #{inspect(conn)}")
    send_resp(conn, 404, "not found")
  end
end
