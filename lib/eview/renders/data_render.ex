defmodule EView.DataRender do
  @moduledoc """
  This module renders `data` property from response structure.
  """

  @doc """
  Render new `data` property for API response.

  For objects it will assign `data.type` property based on module name that defines your view.
  You can put `type` property to your response body to override this behavior.
  """
  def render(data, _conn) when is_list(data), do: data
  def render(%{type: _} = data, _conn), do: data
  def render(%{"type" => _} = data, _conn), do: data

  def render(data, conn) when is_map(data) do
    data
    |> add_object_name(conn)
  end

  defp add_object_name(data, %{private: %{phoenix_view: view_module}}) when data != %{} do
    data
    |> Map.put_new(:type, extract_object_name(view_module))
  end

  defp add_object_name(data, %{private: %{phoenix_view: view_module}}), do: data
  defp add_object_name(data, _), do: data

  def extract_object_name(view_module) do
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
