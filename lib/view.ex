defmodule EView do
  @moduledoc """
  A module defining __using__ hooks for controllers,
  views and so on.

  This can be used in your application as:

      use EView, :controller
      use EView, :view
  """

  def controller do
    quote do
      import EView.Controller
    end
  end

  def view do
    quote do
      import EView.View
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end

# TODO: idempotency_key plug that will receive header and set it back to `conn`
# TODO: pagination

defmodule EView.MetaView do
  import Plug.Conn

  def render(data, %{conn: conn}) do
    %{
      url: get_url(conn),
      type: get_data_type(data),
      code: get_http_status(conn),
      request_id: get_request_id(conn)
    }
    |> add_impotency_key(conn)
  end

  defp get_url(%Plug.Conn{scheme: scheme, host: host, port: 80, path_info: path_info}) do
    Atom.to_string(scheme) <> "://" <> host <> "/" <> Path.join(path_info)
  end

  defp get_url(%Plug.Conn{scheme: scheme, host: host, port: port, path_info: path_info}) do
    Atom.to_string(scheme) <> "://" <> host <> ":" <> to_string(port) <> "/" <> Path.join(path_info)
  end

  defp get_data_type(data) when is_list(data), do: "list"
  defp get_data_type(_data), do: "object"

  defp get_http_status(%Plug.Conn{status: status}), do: status
  defp get_http_status(_conn), do: 200

  defp get_request_id(conn) do
    conn
    |> get_resp_header("x-request-id")
    |> List.first
  end

  defp add_impotency_key(meta, %Plug.Conn{} = conn) do
    case get_req_header(conn, "x-idempotency-key") do
      [idempotency_key | _] ->
        meta
        |> Map.put(:idempotency_key, idempotency_key)
      _ ->
        meta
    end
  end
end

defmodule EView.DataView do
  # List type is specified in `meta`
  def render(data, _assigns) when is_list(data), do: data
  # If developer passed his type, we will not override it
  def render(%{type: _} = data, _assigns), do: data

  def render(data, assigns) when is_map(data) do
    data
    |> add_object_name(assigns)
  end

  defp add_object_name(data, %{view_module: view_module}) do
    data
    |> Map.put_new(:type, extract_object_name(view_module))
  end

  defp extract_object_name(view_module) do
    view_module
    |> to_string
    |> String.split(".")
    |> List.last
    |> Macro.underscore
    |> String.split("_")
    |> Enum.filter(fn module_part ->
      not module_part in ["view"]
    end)
    |> Enum.join("_")
  end
end

defmodule EView.ErrorView do
  # TODO: traverse changeset and ex_json_schema validation errors

  def render(error) do
    error
  end
end

defmodule EView.View do
  alias EView.{MetaView, ErrorView, DataView}

  # TODO: allow to use any assign expressions
  defmacro view(name, assigns, do: block) do
    function_name = String.to_atom("render")
    quote do
      def unquote(function_name)(unquote(name), unquote(assigns)), do: unquote(block) |> format(unquote(assigns))
    end
  end

  # TODO: modelview
  # TODO: errorview
  # TODO: add default 500 error

  # HTTP 4XX, 5XX status codes - Error Response
  def format(data, %{status: status} = assigns) when 400 <= status and status < 600 do
    %{
      meta: MetaView.render(data, assigns),
      error: ErrorView.render(data)
    }
  end

  # HTTP 2XX, 3XX and all other status codes - Success Response
  def format(data, assigns) do
    %{
      meta: MetaView.render(data, assigns),
      data: DataView.render(data, assigns)
    }
    |> put_paging(assigns)
    |> put_urgent(assigns)
    |> put_sandbox(assigns)
  end

  # Add `paging` property. To use it just add `paging` in `render/2` assigns.
  defp put_paging(data, %{paging: paging}), do: data |> Map.put(:paging, paging)
  defp put_paging(data, _assigns), do: data

  # Add `urgent` property. To use it just add `urgent` in `render/2` assigns.
  defp put_urgent(data, %{urgent: urgent}), do: data |> Map.put(:urgent, urgent)
  defp put_urgent(data, _assigns), do: data

  # Add `sandbox` property. To use it just add `sandbox` in `render/2` assigns.
  defp put_sandbox(data, %{sandbox: sandbox}) do
    if Mix.env in [:test, :dev], do: Map.put(data, :sandbox, sandbox), else: data
  end
  defp put_sandbox(data, _assigns), do: data
end


# {
#   "meta": {
#     "url": "https://qbill.ly/transactions/",
#     "type": "list",
#     "code": "200",
#     "idempotency_key": "iXXekd88DKqo",
#     "request_id": "qudk48fFlaP"
#   },
#   "urgent": {
#     "notifications": ["Read new emails!"],
#     "unseen_payments": 10
#   },
#   "data": {
#     "type": "resource_name",
#     <...>
#   },
#   "paging": {
#     "limit": 50,
#     "cursors": {
#       "starting_after": "MTAxNTExOTQ1MjAwNzI5NDE=",
#       "ending_before": "NDMyNzQyODI3OTQw"
#     },
#     "has_more": true
#   },
#   "sandbox": {
#     "debug_varibale": "39384",
#     "live": "false"
#   }
# }
