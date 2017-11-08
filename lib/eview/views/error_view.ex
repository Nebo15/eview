defmodule EView.Views.Error do
  @moduledoc """
  Views for different kind of 4xx and 5xx error of your application.
  """
  @internal_error_templates ["500.json", "501.json", "503.json", "505.json"]

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
    |> put_message(assigns)
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
    |> put_message(assigns)
  end

  def render("403.json", assigns) do
    %{type: :forbidden}
    |> put_type(assigns)
    |> put_invalid(assigns)
    |> put_message(assigns)
  end

  @doc """
  This render will be used by-default for non-existent routes. You can use it in your controller:

        conn |> render("404.json", %{type: my_type})
  """
  def render("404.json", assigns) do
    %{type: :not_found}
    |> put_type(assigns)
    |> put_message(assigns)
  end

  def render("406.json", assigns) do
    %{
      type: :content_type_invalid,
      invalid: [%{
        entry_type: :header,
        entry: "Accept"
      }],
      message: "Accept header is missing or invalid. Try to set 'Accept: application/json' header."
    }
    |> put_message(assigns)
  end

  @doc """
  This render should be used for PUT requests that can not be completed.
  """
  def render("409.json", assigns) do
    %{
      type: :request_conflict,
      message: "The request could not be completed due to a conflict with the current state of the resource."
    }
    |> put_message(assigns)
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
    |> put_message(assigns)
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
    |> put_message(assigns)
  end

  def render("424.json", assigns) do
    %{
      type: :failed_dependency,
      message: "The method could not be performed on the resource because the requested action depended on another " <>
               "action and that action failed."
    }
    |> put_message(assigns)
  end

  @doc """
  This render will be used by-default for internal errors. You can use it in your controller:

        conn |> render("500.json", %{type: my_type})
  """
  def render(template, assigns) when template in @internal_error_templates do
    %{type: :internal_error}
    |> put_type(assigns)
    |> put_message(assigns)
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

  defp put_message(body, %{message: message}) when is_binary(message) do
    body
    |> Map.put(:message, message)
  end
  defp put_message(body, _), do: body
end
