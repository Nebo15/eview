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
    |> put_test_assignes(map_keys_to_atom(params))
    |> render("page.json", map_keys_to_atom(params))
  end

  defp put_test_assignes(conn, params) do
    urgent  = Map.get(params, :urgent)
    paging  = Map.get(params, :paging)
    sandbox = Map.get(params, :sandbox)

    conn = if urgent,  do: assign(conn, :urgent,  urgent), else: conn
    conn = if paging,  do: assign(conn, :paging,  paging), else: conn
    conn = if sandbox, do: assign(conn, :sandbox, sandbox), else: conn

    conn
  end

  defp map_keys_to_atom(map) when is_map(map) do
    for {key, val} <- map, into: %{}, do: {String.to_atom(key), map_keys_to_atom(val)}
  end

  defp map_keys_to_atom(any), do: any
end
