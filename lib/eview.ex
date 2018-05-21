# TODO: validate headers and other non-json fields
defmodule EView do
  @moduledoc """
  This plug will take `body_params` from Plug.Conn structure
  and re-render it with appropriate structure to `resp_body`.

  What is appropriate structure? Take look at [Nebo #15 API Manifest](http://docs.apimanifest.apiary.io/#).

  # Example:
  Add to your `endpoint.ex` before Plug.Parsers plug:

        plug EView
        plug EView.Plugs.Idempotency
  """
  @behaviour Plug

  import Plug.Conn

  def init(options), do: options

  @spec call(Conn.t(), any) :: Conn.t()
  def call(conn, _options) do
    conn
    |> register_before_send(&update_reponse_body/1)
  end

  defp update_reponse_body(%{resp_body: []} = conn), do: conn
  defp update_reponse_body(%{resp_body: ""} = conn), do: conn
  defp update_reponse_body(%{resp_body: nil} = conn), do: conn
  defp update_reponse_body(%{resp_body: resp_body} = conn), do: put_response(conn, resp_body)

  @doc """
  Update `body` and add all meta objects that is required by API Manifest structure.
  """
  def wrap_body(body, %Plug.Conn{} = conn) when is_map(body) or is_list(body) do
    body
    |> EView.Renders.Root.render(conn)
  end

  def put_response(conn, resp_body) do
    case Poison.Parser.parse(resp_body) do
      {:ok, result} ->
        resp =
          result
          |> wrap_body(conn)
          |> Poison.encode_to_iodata!()

        %{conn | resp_body: resp}

      {:error, _} ->
        %{conn | resp_body: resp_body}
    end
  end
end
