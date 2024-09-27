defmodule Martcache.Application do
  require Logger
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Starts a worker by calling: Martcache.Worker.start_link(arg)
      # {Martcache.Worker, arg}
      {Bandit, plug: Martcache.Router, scheme: :http, port: 3033},
      #
      {DynamicSupervisor, name: Martcache.DownloadSupervisor, strategy: :one_for_one},
      {Task.Supervisor, name: Martcache.TaskSupervisor, strategy: :one_for_one}
    ]

    Logger.error("Starting #{__MODULE__}")

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Martcache.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
