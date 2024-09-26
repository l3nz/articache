defmodule Martcache.DownloadSrv do
  use GenServer
  require Logger

  # client

  def download(url) do
    case :global.whereis_name(url) do
      ppid when is_pid(ppid) ->
        GenServer.call(ppid, :get_file_name, :infinity)

      _ ->
        {:ok, pid} =
          DynamicSupervisor.start_child(Martcache.DownloadSupervisor, {__MODULE__, url})

        GenServer.call(pid, :download_file, :infinity)
    end
  end

  # server

  def start_link(url) do
    GenServer.start_link(__MODULE__, url, name: {:via, :global, url})
  end

  def init(url) do
    # Start downloading the URL asynchronously
    {:ok, %{url: url, file_name: nil}}
  end

  def handle_call(:download_file, _from, %{url: url} = state) do
    file_name = "f-#{System.unique_integer()}.tmp"
    Logger.error("Now downloading #{url} to #{file_name}")
    download_url(url, file_name)
    Logger.error("Finished #{url} to #{file_name}")

    {:reply, file_name, %{state | file_name: file_name}}
  end

  def handle_call(:get_file_name, _from, %{file_name: file_name} = state) do
    {:reply, file_name, state}
  end

  defp download_url(url, file_name) do
    # Download the URL and store it in a file
    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{body: body}} ->
        File.write!(file_name, body)
        file_name

      {:error, e} ->
        # Handle download errors
        Logger.error("Failed to download URL: #{url} -> #{inspect(e)}")
        ""
    end
  end

  def handle_cast({:downloaded, file_name}, %{url: url} = state) do
    # Store the file name in the state
    Logger.info("Downloaded URL: #{url} to file: #{file_name}")
    {:noreply, %{state | file_name: file_name}}
  end
end
