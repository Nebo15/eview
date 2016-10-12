# TODO: idempotency_key plug that will receive header and set it back to `conn`
# TODO: pagination
# TODO: move acceptance case to this module (with helpers that validate structure and makes easy to extract data)

defmodule EView do
  @moduledoc """
  This module defines common helpers and macros that should be used in views of your API app.

  # Example:
      defmodule Demo.PageView do
        use Demo.Web, :view
        use EView

        view("page.json", %{data: data}) do
          data
        end
      end

  Also you want to don't forget to set errors view in your Phoenix application:

      config :demo, Demo.Endpoint,
        render_errors: [view: EView]
  """
  alias EView.{MetaView, ErrorView, DataView}

  @data_type_object "object"
  @data_type_list "list"

  defmacro __using__(:error) do
    quote location: :keep do
      import EView

      view("404.json", _assigns) do
        %{type: :not_found}
      end

      view("500.json", _assigns) do
        %{type: :internal_error}
      end

      def template_not_found(_template, assigns) do
        render "500.json", assigns
      end
    end
  end

  defmacro __using__(_) do
    quote location: :keep do
      import EView
    end
  end

  @doc """
  Define a render that will mutate its result into defined `meta`-`data` view structure.
  """
  defmacro defview(name, assigns, do: block) do
    function_name = String.to_atom("render")
    quote do
      # TODO: maybe get object name from render name instead of view module?
      def unquote(function_name)(unquote(name), unquote(assigns) = all_assigns) do
        unquote(block)
        |> apply_format(all_assigns)
      end
    end
  end

  # TODO: modelview
  # TODO: errorview
  # TODO: add default 500 error

  # HTTP 4XX, 5XX status codes - Error Response
  def apply_format(data, %{status: status} = assigns) when 400 <= status and status < 600 do
    %{
      meta: MetaView.render(@data_type_object, assigns),
      error: ErrorView.render(data)
    }
  end

  # HTTP 2XX, 3XX and all other status codes - Success Response
  def apply_format(data, assigns) do
    %{
      meta: MetaView.render(get_data_type(data), assigns),
      data: DataView.render(data, assigns)
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
