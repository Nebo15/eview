defmodule EView.DataView do
  @moduledoc """
  This module builds common `data` structure from response data and assigns.
  """

  @doc """
  Render new `data` object by `render/2` assigns and data that will be sent to API consumer.

  For objects it will assign `data`.`type` property based on module name that defines your view.
  You can put `type` property to `data` to override this behavior.
  """
  def render(data, _assigns) when is_list(data), do: data
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
