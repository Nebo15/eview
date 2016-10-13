defmodule EView.AcceptanceCase do
  @moduledoc """
  This module defines the test case to be used by
  acceptance tests. It can allow run tests in async when each SQL.Sandbox connection will be
  binded to a specific test.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      import Ecto.Query, only: [from: 2]
      import Demo.Router.Helpers

      use HTTPoison.Base

      @endpoint Demo.Endpoint

      # Configure acceptance testing on different host:port
      conf = Application.get_env(:eview, Demo.Endpoint)
      host = conf[:http][:host] || "localhost"
      port = conf[:http][:port]

      @http_uri "http://#{host}:#{port}/"

      def process_url(url) do
        @http_uri <> url
      end

      defp process_request_headers(headers) do
        [
          {"x-request-id", "my_request_id_000000"},
          {"x-idempotency-key", "TestIdempotencyKey"},
          {"content-type", "application/json"},
        ] ++ headers
      end

      defp process_request_body(body) do
        body
        |> Poison.encode!
      end

      defp process_response_body(body) do
        body
        |> Poison.decode!
      end
    end
  end
end
