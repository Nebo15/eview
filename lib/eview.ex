defmodule EView do
  @moduledoc """
  This plug will take `body_params` from Plug.Conn structure
  and re-render it with appropriate structure to `resp_body`.
  """

  @behaviour Plug

  import Plug.Conn

  def init(options), do: options

  @spec call(Conn.t, any) :: Conn.t
  def call(conn, _options) do
    conn
    |> register_before_send(&format_reponse/1)
  end

  def format_reponse(%{resp_body: resp_body} = conn) do
    resp = resp_body
    |> Poison.Parser.parse!
    |> EView.RootRender.render(conn)
    |> Poison.encode_to_iodata!

    %{conn | resp_body: resp}
  end
end
