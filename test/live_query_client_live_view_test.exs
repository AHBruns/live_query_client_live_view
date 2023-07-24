defmodule LiveQueryClientLiveViewTest do
  use PhxTestAppWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  test "using a static query", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/using_a_static_query")
    assert html =~ "PhxTestAppWeb.UsingAStaticQueryLive.Query"
  end

  test "using a dynamic query", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/using_a_dynamic_query")
    initial_render = view |> element("#value") |> render()
    assert initial_render =~ "1</span>"
    Phoenix.PubSub.subscribe(PhxTestApp.PubSub, "dynamic_query:events")

    :ok =
      Phoenix.PubSub.broadcast(
        PhxTestApp.PubSub,
        "dynamic_query:commands",
        {"dynamic_query:commands", :change}
      )

    assert_receive {"dynamic_query:events", :changed}
    changed_render = view |> element("#value") |> render()
    assert changed_render =~ "2</span>"
  end

  test "sharings a query" do
    {:ok, view1, _html} = live(Phoenix.ConnTest.build_conn(), "/sharing_a_query")
    {:ok, view2, _html} = live(Phoenix.ConnTest.build_conn(), "/sharing_a_query")

    assert view1 |> element("#value") |> render() == view2 |> element("#value") |> render()
  end
end
