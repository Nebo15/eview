defmodule EView.MetaRender do
  @moduledoc """
  This module renders `meta` property from response structure.
  """
  import Plug.Conn

  @doc """
  Renders `meta` view by data_type (may be `object` or `list`) and connection `conn`.
  """
  def render(data_type, conn) do
    %{
      url: get_url(conn),
      type: data_type,
      code: get_http_status(conn),
      request_id: get_request_id(conn)
    }
    |> put_impotency_key(conn)
  end

  defp get_url(%Plug.Conn{scheme: scheme, host: host, port: 80, path_info: path_info}) do
    Atom.to_string(scheme) <> "://" <> host <> "/" <> Path.join(path_info)
  end

  defp get_url(%Plug.Conn{scheme: scheme, host: host, port: port, path_info: path_info}) do
    Atom.to_string(scheme) <> "://" <> host <> ":" <> to_string(port) <> "/" <> Path.join(path_info)
  end

  defp get_http_status(%Plug.Conn{status: status}) when not is_nil(status), do: status
  defp get_http_status(_conn), do: 200

  defp get_request_id(conn) do
    conn
    |> get_resp_header("x-request-id")
    |> List.first
  end

  defp put_impotency_key(meta, %Plug.Conn{} = conn) do
    case get_resp_header(conn, "x-idempotency-key") do
      [idempotency_key | _] ->
        meta
        |> Map.put(:idempotency_key, idempotency_key)
      _ ->
        meta
    end
  end
end
