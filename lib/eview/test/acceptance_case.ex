defmodule EView.AcceptanceCase do
  @moduledoc """
  This module defines the test case to be used by
  acceptance tests. It can allow run tests in async when each SQL.Sandbox connection will be
  binded to a specific test.
  """

  use ExUnit.CaseTemplate

  using(opts) do
    quote location: :keep, bind_quoted: [opts: opts] do
      unless opts[:otp_app] do
        throw("You need to specify `otp_app` when using AcceptanceCase.")
      end

      unless opts[:endpoint] do
        throw("You need to specify `endpoint` when using AcceptanceCase.")
      end

      # Configure acceptance testing on different host:port
      conf = Application.get_env(opts[:otp_app], opts[:endpoint])
      host = System.get_env("CONTAINER_HTTP_HOST") || conf[:http][:host] || "localhost"
      port = System.get_env("CONTAINER_HTTP_PORT") || conf[:http][:port]

      @http_uri "http://#{host}:#{port}/"
      @repo opts[:repo]
      @endpoint opts[:endpoint]
      @headers opts[:headers] || []

      use HTTPoison.Base
      import EView.AcceptanceCase
      # if opts[:repo] do
      #   alias @repo
      # end

      def process_url(url) do
        @http_uri <> url
      end

      if is_atom(opts[:repo]) and not is_nil(opts[:repo]) and opts[:async] and Code.ensure_loaded?(Ecto) do
        defp process_request_headers(headers) do
          meta = Phoenix.Ecto.SQL.Sandbox.metadata_for(@repo, self())

          encoded =
            {:v1, meta}
            |> :erlang.term_to_binary()
            |> Base.url_encode64()

          headers ++ @headers ++ [{"content-type", "application/json"}, {"user-agent", "BeamMetadata (#{encoded})"}]
        end
      else
        defp process_request_headers(headers) do
          headers ++ @headers ++ [{"content-type", "application/json"}]
        end
      end

      defp process_request_body(body) do
        case body do
          {:multipart, _} -> body
          _ -> body |> Poison.encode!()
        end
      end

      defp process_response_body(body) do
        body
        |> Poison.decode!()
      end

      if is_atom(opts[:repo]) and not is_nil(opts[:repo]) and Code.ensure_loaded?(Ecto) do
        setup tags do
          :ok = Ecto.Adapters.SQL.Sandbox.checkout(@repo)

          unless tags[:async] do
            Ecto.Adapters.SQL.Sandbox.mode(@repo, {:shared, self()})
          end

          :ok
        end
      end
    end
  end

  def get_body(map) do
    map
    |> Map.get(:body)
  end
end
