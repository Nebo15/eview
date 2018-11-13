defmodule Demo.PageController do
  @moduledoc false

  use Demo.Web, :controller
  alias Demo.SampleSchema

  def create(conn, params) do
    params
    |> Map.get("env", "prod")
    |> String.to_atom()
    |> Mix.env()

    conn
    |> put_status(Map.get(params, "status", 200))
    |> put_test_assignes(map_keys_to_atom(params))
    |> render("page.json", map_keys_to_atom(params))
  end

  def validate_changeset(conn, params) do
    changeset =
      %SampleSchema{}
      |> SampleSchema.changeset(params)

    case changeset.valid? do
      true ->
        conn
        |> put_status(200)
        |> render("page.json", map_keys_to_atom(params))

      _ ->
        conn
        |> put_status(422)
        |> put_view(EView.Views.ValidationError)
        |> render("422.json", changeset)
    end
  end

  def validate_schema(conn, params) do
    schema = %{
      "type" => "object",
      "properties" => %{
        "originator" => %{
          "type" => "string",
          "enum" => ["a", "b"]
        },
        "loans_count" => %{
          "type" => "integer"
        }
      },
      "required" => ["originator", "loans_count"],
      "additionalProperties" => false
    }

    validation =
      schema
      |> NExJsonSchema.Schema.resolve()
      |> NExJsonSchema.Validator.validate(params["data"])

    case validation do
      :ok ->
        conn
        |> put_status(200)
        |> render("page.json", map_keys_to_atom(params))

      {:error, err} ->
        conn
        |> put_status(422)
        |> put_view(EView.Views.ValidationError)
        |> render("422.json", %{schema: err})
    end
  end

  defp put_test_assignes(conn, params) do
    urgent = Map.get(params, :urgent)
    paging = Map.get(params, :paging)
    sandbox = Map.get(params, :sandbox)

    conn = if urgent, do: assign(conn, :urgent, urgent), else: conn
    conn = if paging, do: assign(conn, :paging, paging), else: conn
    conn = if sandbox, do: assign(conn, :sandbox, sandbox), else: conn

    conn
  end

  defp map_keys_to_atom(map) when is_map(map) do
    for {key, val} <- map, into: %{}, do: {String.to_atom(key), map_keys_to_atom(val)}
  end

  defp map_keys_to_atom(any), do: any
end
