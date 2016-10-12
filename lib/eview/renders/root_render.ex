# TODO: pagination
# TODO: move acceptance case to this module (with helpers that validate structure and makes easy to extract data)

defmodule EView.RootRender do
  @moduledoc """
  This module defines common helpers and macros that should be used in views of your API app.

  Also you want to don't forget to set errors view in your Phoenix application:

      config :demo, Demo.Endpoint,
        render_errors: [view: EView.ErrorRenderer]
  """
  alias EView.{MetaRender, ErrorRender, DataRender}

  @data_type_object "object"
  @data_type_list "list"

  # TODO: modelview
  # TODO: errorview
  # TODO: add default 500 error

  # HTTP 4XX, 5XX status codes - Error Response
  def render(error, %{status: status} = conn) when 400 <= status and status < 600 do
    %{
      meta: MetaRender.render(@data_type_object, conn),
      error: ErrorRender.render(error)
    }
  end

  # HTTP 2XX, 3XX and all other status codes - Success Response
  def render(data, %{assigns: assigns} = conn) do
    %{
      meta: MetaRender.render(get_data_type(data), conn),
      data: DataRender.render(data, conn)
    }
    |> put_paging(assigns)
    |> put_urgent(assigns)
    |> put_sandbox(assigns)
  end

  # Add `paging` property. To use it just add `paging` in `render/2` assigns.
  defp put_paging(%{meta: %{type: "list"}} = data,
                  %{paging: %{
                    limit: limit,
                    cursors: %{starting_after: _, ending_before: _},
                    has_more: has_more
                  } = paging}) when is_integer(limit) and is_boolean(has_more) do
    data
    |> Map.put(:paging, paging)
  end
  defp put_paging(data, _assigns), do: data

  # Add `urgent` property. To use it just add `urgent` in `render/2` assigns.
  defp put_urgent(data, %{urgent: urgent}), do: data |> Map.put(:urgent, urgent)
  defp put_urgent(data, _assigns), do: data

  # Add `sandbox` property. To use it just add `sandbox` in `render/2` assigns.
  defp put_sandbox(data, %{sandbox: sandbox}) do
    if Mix.env in [:test, :dev], do: Map.put(data, :sandbox, sandbox), else: data
  end
  defp put_sandbox(data, _assigns), do: data

  # Get string for `meta.type` property.
  defp get_data_type(data) when is_list(data), do: @data_type_list
  defp get_data_type(_data), do: @data_type_object
end
