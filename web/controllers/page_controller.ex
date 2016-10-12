defmodule Demo.PageController do
  @moduledoc """
  Sample controller for generated application.
  """

  use Demo.Web, :controller

  def create(conn, params) do
    params
    |> Map.get("env", "prod")
    |> String.to_atom
    |> Mix.env

    conn
    |> put_status(Map.get(params, "status", 200))
    |> render("page.json", map_keys_to_atom(params))
  end

  defp map_keys_to_atom(map) when is_map(map) do
    for {key, val} <- map, into: %{}, do: {String.to_atom(key), map_keys_to_atom(val)}
  end

  defp map_keys_to_atom(any), do: any
end
