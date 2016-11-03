defmodule EView.Plugs.IdempotencyAcceptanceTest do
    use EView.AcceptanceCase,
    async: true,
    otp_app: :eview,
    endpoint: Demo.Endpoint,
    headers: [{"x-request-id", "my_request_id_000000"},
              {"x-idempotency-key", "TestIdempotencyKey"}]

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
