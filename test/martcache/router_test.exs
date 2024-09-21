defmodule Martcache.RouterTest do
  # test/martcache/router_test.exs

  use ExUnit.Case, async: true
  use Plug.Test
  doctest Martcache.Router
  alias Martcache.Router

  test "Homepage" do
    assert %{status: 200} =
             conn(:get, "/")
             |> Router.call([])
  end

  test "Pluto" do
    assert %{status: 200, resp_body: "Pluto"} =
             conn(:get, "/pluto/anna/bella")
             |> Router.call([])

    assert %{status: 200, resp_body: "Pluto"} =
             conn(:get, "/pluto/anna/bella/zebra.jsp")
             |> Router.call([])

    assert %{status: 201, resp_body: "Pluto"} =
             conn(:get, "/pluto/zix")
             |> Router.call([])
  end

  test "Sample URL not found" do
    assert %{status: 404} =
             conn(:get, "/unk/nown")
             |> Router.call([])
  end
end
