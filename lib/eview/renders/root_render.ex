defmodule EView.Renders.Root do
  @moduledoc """
  This module converts map to a structure that corresponds
  to [Nebo #15 API Manifest](http://docs.apimanifest.apiary.io/) response structure.
  """
  alias EView.Renders.{Meta, Error, Data}

  @doc """
  Render response object or error description following to our guidelines.

  This method will look into status code and:
    * create `error` property from response data when HTTP status code is `4XX` or `5XX`;
    * create `data` property for other HTTP status codes.
  """
  def render(error, %{status: status} = conn) when 400 <= status and status < 600 do
    %{
      meta: Meta.render(error, conn),
      error: Error.render(error)
    }
  end

  def render(data, %{assigns: assigns} = conn) do
    %{
      meta: Meta.render(data, conn),
      data: Data.render(data, conn)
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
end
