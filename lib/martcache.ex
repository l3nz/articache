defmodule Martcache do
  require Logger

  @moduledoc """
  Documentation for `Martcache`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Martcache.hello()
      :world

  """
  def hello do
    Logger.error("ciao")

    :world
  end

  @doc """
  Starts the application.
  """
  def up(), do: Martcache.Application.start(0, 0)

  #  def download_file() do
  #    {:ok, :saved_to_file} = :httpc.request(:get, {'https://elixir-lang.org/images/logo/logo.png', []}, [], [stream: '/tmp/elixir'])
  #  end
end
