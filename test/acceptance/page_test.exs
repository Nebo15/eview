defmodule Demo.PageAcceptanceTest do
  use EView.AcceptanceCase, async: true

  test "GET /page" do
    %{body: body} = get!("page") |> IO.inspect

    body
    |> Poison.decode!
    |> IO.inspect

    # assert body == ~S({"page":{"detail":"This is page."}})

    :timer.sleep(100)
  end
end
