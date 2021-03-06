defmodule EView.Plugs.Idempotency do
  @moduledoc """
  This Plug allows to take `X-Idempotency-Key` header from request and sent it back to client.

  ## Examples

  Modify your `endpoint.ex` and add before `plug MyApp.Router`:

      plug EView.Plugs.Idempotency

  """
  @behaviour Plug
  import Plug.Conn

  def init(opts), do: opts

  @spec call(Conn.t(), any) :: Conn.t()
  def call(conn, _options) do
    case get_req_header(conn, "x-idempotency-key") do
      [idempotency_key | _] ->
        conn
        |> put_resp_header("x-idempotency-key", idempotency_key)

      _ ->
        conn
    end
  end
end
