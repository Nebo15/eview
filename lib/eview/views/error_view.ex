defmodule EView.ErrorView do
  @moduledoc """
  Error view that can be used in Phoenix:

      config :myapp, MyApp.Endpoint,
        render_errors: [view: EView.ErrorView, accepts: ~w(json)]
  """
  def render(template, assigns \\ %{})
  @doc """
  Render error for malformed request (for example when Plug.Parser can't parse content type).
  """
  def render("400.json", assigns) do
    # This bitch don't want to handle before_send
    %{
      type: :request_malformed,
      invalid: [%{
        entry_type: :request,
        rules: [
          %{rule: :json}
        ]
      }],
      message: "Malformed request. Probably, you have sent corrupted JSON."
    }
    |> EView.RootRender.render(assigns[:conn])
  end

  @doc """
  Render access denied error. Can have custom `type` and `invalid` error fields.

  For invalid tokens it should look like:

      {
        meta: {
          code: 401
        },
        error: {
          type: :access_denied,
          invalid:[{
            entry_type: "header",
            entry: "Authorization",
            rules: [
              {rule: "scopes", params:[list_of_scopes_needed]}
            ]
          }]
        }
      }
  """
  def render("401.json", assigns) do
    %{type: :access_denied}
    |> put_type(assigns)
    |> put_invalid(assigns)
  end

  @doc """
  This render will be used by-default for non-existent routes. You can use it in your controller:

        conn |> render("404.json", %{type: my_type})
  """
  def render("404.json", assigns) do
    %{type: :not_found}
    |> put_type(assigns)
  end

  @doc """
  This render should be used for PUT requests that can not be completed.
  """
  def render("409.json", _assigns) do
    %{
      type: :request_conflict,
      message: "The request could not be completed due to a conflict with the current state of the resource."
    }
  end

  def render("413.json", assigns) do
    # This bitch don't want to handle before_send
    %{
      type: :request_too_large,
      invalid: [%{
        entry_type: :request,
        rules: [
          %{rule: :size}
        ]
      }],
      message: "Request body is too large."
    }
    |> EView.RootRender.render(assigns[:conn])
  end

  def render("415.json", assigns) do
    # This bitch don't want to handle before_send
    %{
      type: :content_type_invalid,
      invalid: [%{
        entry_type: :header,
        entry: "Content-Type"
      }],
      message: "Invalid Content-Type header. Try to set 'Content-Type: application/json' header: " <>
               "http://docs.apimanifest.apiary.io/#introduction/interacting-with-api/content-type."
    }
    |> EView.RootRender.render(assigns[:conn])
  end

  @doc """
  This render will be used by-default for internal errors. You can use it in your controller:

        conn |> render("500.json", %{type: my_type})
  """
  def render("500.json", assigns) do
    %{type: :internal_error}
    |> put_type(assigns)
  end

  defp put_type(body, %{type: type}) when is_atom(type) or is_binary(type) do
    body
    |> Map.put(:type, type)
  end
  defp put_type(body, _), do: body

  defp put_invalid(body, %{invalid: invalid}) when is_map(invalid) do
    body
    |> Map.put(:invalid, invalid)
  end
  defp put_invalid(body, _), do: body
end
