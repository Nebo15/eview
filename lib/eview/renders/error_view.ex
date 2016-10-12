defmodule EView.ErrorRender do
  @moduledoc """
  This module builds common `error` structure from response data and assigns.
  It should be used whenever you want to notify API consumer about error.
  """

  # TODO: traverse changeset and ex_json_schema validation errors

  @doc """
  Renders error view.

  Also it can traverse `Ecto.Changeset` and `ex_json_schema` validation errors,
  so they will match our response format.
  """
  def render(error) when is_map(error) do
    error
  end
end
