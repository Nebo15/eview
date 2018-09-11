defmodule EView.Test do
  use ExUnit.Case, async: true
  alias EView.Renders.Root

  test "returns raw response" do
    conn = %Plug.Conn{}
    resp_body = "raw_exception_html_here"

    assert %Plug.Conn{resp_body: "raw_exception_html_here"} = EView.put_response(conn, resp_body)
  end

  test "returns normally parsed response" do
    conn = %Plug.Conn{}
    resp_body = ~s({"a":1})

    %Plug.Conn{resp_body: resp_body} = EView.put_response(conn, resp_body)

    result =
      resp_body
      |> Jason.decode!()
      |> Map.get("data")

    assert %{"a" => 1} = result
  end

  test "paging for list with Scrivener paging format" do
    paging = %{
      page_number: 3,
      page_size: 5,
      total_pages: 5,
      total_entries: 25,
      entries: []
    }

    conn = %Plug.Conn{
      scheme: :http,
      host: "test",
      port: 80,
      request_path: "test",
      assigns: %{paging: paging}
    }

    assert Map.delete(paging, :entries) == Root.render([%{id: 1}, %{id: 2}], conn).paging
  end

  test "paging for list with keys as string" do
    paging = %{
      "page_number" => 3,
      "page_size" => 5,
      "total_pages" => 5,
      "total_entries" => 25,
      "entries" => []
    }

    conn = %Plug.Conn{
      scheme: :http,
      host: "test",
      port: 80,
      request_path: "test",
      assigns: %{paging: paging}
    }

    assert %{
             page_number: 3,
             page_size: 5,
             total_pages: 5,
             total_entries: 25
           } == Root.render([%{id: 1}, %{id: 2}], conn).paging
  end
end
