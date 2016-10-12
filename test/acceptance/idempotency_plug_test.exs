defmodule EView.IdempotencyPlugAcceptanceTest do
  use EView.AcceptanceCase, async: true
  use Plug.Test

  test "renders 404 error" do
    %{headers: headers} = post!("not_found", %{
      data: %{
        type: "invalid_data",
      }
    })

    refute is_nil(Enum.find(headers, fn(x) -> x == {"x-idempotency-key", "TestIdempotencyKey"} end))
  end
end
