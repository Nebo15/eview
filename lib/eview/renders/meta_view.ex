defmodule EView.Renders.Meta do
  @moduledoc """
  This module renders `meta` property from response structure.
  """
  import Plug.Conn

  @data_type_object "object"
  @data_type_list "list"

  @doc """
  Renders `meta` view by data_type (may be `object` or `list`) and connection `conn`.
  """
  def render(data, conn) do
    status = get_http_status(conn)

    %{
      url: get_resourse_url(conn, get_resource_id(data), status),
      type: get_data_type(data),
      code: status,
      request_id: get_request_id(conn)
    }
    |> put_impotency_key(conn)
  end

  defp get_resourse_url(conn, resrouce_id, 201) when not is_nil(resrouce_id) do
    get_resourse_url(conn) <> "/"  <> to_string(resrouce_id)
  end

  defp get_resourse_url(conn, _resrouce_id, _status) do
    get_resourse_url(conn)
  end

  defp get_resourse_url(%Plug.Conn{scheme: scheme, host: host, port: 80, request_path: request_path}) do
    Atom.to_string(scheme) <> "://" <> host <> request_path
  end

  defp get_resourse_url(%Plug.Conn{scheme: scheme, host: host, port: port, request_path: request_path}) do
    Atom.to_string(scheme) <> "://" <> host <> ":" <> to_string(port) <> request_path
  end

  defp get_http_status(%Plug.Conn{status: status}) when not is_nil(status), do: status
  defp get_http_status(_conn), do: 200

  defp get_data_type(data) when is_list(data), do: @data_type_list
  defp get_data_type(_data), do: @data_type_object

  defp get_resource_id(%{id: id}), do: id
  defp get_resource_id(_), do: nil

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
