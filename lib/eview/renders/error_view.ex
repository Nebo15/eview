defmodule EView.ErrorRender do
  @moduledoc """
  This module renders `error` property from response structure.
  """

  @doc """
  Renders error view.
  """
  def render(error) when is_map(error) do
    error
  end
end
