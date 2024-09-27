defmodule Martcache.DownloadSrv do
  use GenServer
  require Logger

  @prefixes ["https://repo3.maven.org/maven2", "https://repo1.maven.org/maven2"]

  # client

  @doc """
  Ritorna un path su disco dove si trova il file.
  """
  def download(area, file_path) do
    name = dl_path_for(file_path, area)

    current_pid =
      case :global.whereis_name(name) do
        ppid when is_pid(ppid) ->
          ppid

        _ ->
          {:ok, pid} =
            DynamicSupervisor.start_child(
              Martcache.DownloadSupervisor,
              {__MODULE__, {name, area, file_path, @prefixes}}
            )

          pid
      end

    GenServer.call(current_pid, :download_file, :infinity)
  end

  # server

  def start_link({name, _area, _filepath, _prefixes} = v) do
    GenServer.start_link(__MODULE__, v, name: {:via, :global, name})
  end

  def init({name, area, filepath, prefixes}) do
    state = %{
      url: nil,
      file_name: nil,
      name: name,
      area: area,
      filepath: filepath,
      prefixes: prefixes
    }

    Logger.warning("New state: #{inspect(state)}")

    {:ok, state}
  end

  def handle_call(
        :download_file,
        _from,
        %{area: area, filepath: filepath, prefixes: prefixes} = state
      ) do
    try do
      expected_path = dl_path_for(filepath, area)

      url =
        if !File.exists?(expected_path) do
          # lo scarico
          find_correct_url(stem_for(filepath), prefixes)
        else
          Logger.warning("File found #{expected_path}")
          nil
        end

      if url != nil do
        download_to_file(url, filepath, area)
      end

      {:reply, expected_path, %{state | file_name: expected_path, url: url}}
    catch
      e ->
        with Logger.error("Crashing #{inspect(e)}") do
          {:stop, :normal, nil, state}
        end
    end
  end

  def handle_cast({:downloaded, file_name}, %{url: url} = state) do
    # Store the file name in the state
    Logger.info("Downloaded URL: #{url} to file: #{file_name}")
    {:noreply, %{state | file_name: file_name}}
  end

  @doc """
  Dati i prefissi

      Martcache.TaskSupervisor

  """

  def find_correct_url(url_stem, l_prefixes) do
    Logger.warning("Finding URL for #{url_stem}")

    {:ok, {:ok, url}} =
      Task.Supervisor.async_stream(
        Martcache.TaskSupervisor,
        build_urls(url_stem, l_prefixes),
        &assess_url_exists/1,
        ordered: false,
        max_concurrency: 10,
        timeout: 30_000
      )
      |> Enum.find(fn
        {:ok, {:ok, _url}} -> true
        _ -> false
      end)

    Logger.warning("Found URL for #{url}")

    url
  end

  def build_urls(stem, l_prefix), do: Enum.map(l_prefix, fn p -> "#{p}/#{stem}" end)

  def assess_url_exists(url) do
    Logger.info("Checking #{url}")

    status =
      case HTTPoison.head(url, [], follow_redirect: true) do
        {:ok, %HTTPoison.Response{status_code: n}} when n >= 200 and n < 300 -> :ok
        _ -> :ko
      end

    Logger.warning("Got #{url}: #{inspect(status)}")
    {status, url}
  end

  # asincrono https://www.poeticoding.com/download-large-files-with-httpoison-async-requests/
  def download_to_file(url, l_parts, area) when is_list(l_parts) do
    mkdir_for(l_parts, area)
    file_path = dl_path_for(l_parts, area)

    body = HTTPoison.get!(url, ["User-Agent": "Elixir"], recv_timeout: 300_000).body
    File.write!(file_path, body)
  end

  def dl_path_for(l_parts, area) when is_list(l_parts) and is_binary(area) do
    "./dl/#{area}/#{stem_for(l_parts)}"
  end

  def mkdir_for(l_parts, area) when is_list(l_parts) and is_binary(area) do
    dirs =
      l_parts
      |> Enum.take(length(l_parts) - 1)
      |> dl_path_for(area)

    :ok = File.mkdir_p(dirs)
  end

  def stem_for(l_parts), do: Enum.join(l_parts, "/")
end
