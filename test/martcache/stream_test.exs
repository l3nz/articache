defmodule Martcache.StreamTest do
  alias ElixirLS.LanguageServer.Providers.References
  alias Bandit.HTTP2.Errors.StreamError
  # test/martcache/stream_test.exs

  use ExUnit.Case, async: true
  require Logger

  test "Interrompi uno stream" do
    v =
      Stream.cycle([1, 2, 3])
      |> Stream.take(7)

    assert [1, 2, 3, 1, 2, 3, 1] = Enum.to_list(v)

    vf =
      Stream.cycle([1, 2, 3])
      |> Stream.take_while(fn v -> v < 3 end)

    assert [1, 2] = Enum.to_list(vf)
  end

  @magic 170
  test "Uno stream asincrono" do
    assert {:ok, _pid} = start_sup(MyAsyncStream)

    collection = [100, 300, 20, 30, 180, @magic, 30, 19, @magic, @magic, 402]

    stream =
      Task.Supervisor.async_stream(
        MyAsyncStream,
        collection,
        fn r ->
          unq = inspect(make_ref())
          Logger.warning("Starting #{unq} #{r}")

          :timer.sleep(r)

          ret =
            if r == 70 do
              :ok
            else
              :ko
            end

          Logger.warning("Ending #{unq} #{r}")
          {ret, r, unq}
        end,
        ordered: false,
        max_concurrency: 6
      )

    # Supervisor.stop(pid)

    val =
      stream
      |> Enum.find(fn
        {_, {ok, 170, _}} -> true
        _ -> false
      end)

    Logger.error("Found: #{inspect(val)}")
  end

  defp start_sup(name) do
    children = [
      {Task.Supervisor, name: name, strategy: :one_for_one}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one]
    Supervisor.start_link(children, opts)
  end
end
