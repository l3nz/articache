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
end
