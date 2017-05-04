defmodule EView.Test do
  use ExUnit.Case, async: true

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
      |> List.to_string
      |> Poison.decode!
      |> Map.get("data")

    assert %{"a" => 1} = result
  end
end
