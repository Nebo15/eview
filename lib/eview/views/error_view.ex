defmodule EView.ErrorView do
  @moduledoc """
  Error view that can be used in Phoenix:

      config :myapp, MyApp.Endpoint,
        render_errors: [view: EView.ErrorView, accepts: ~w(json)]
  """

  def render("401.json", %{type: type}) when is_atom(type) or is_binary(type) do
    %{type: type}
  end

  def render("401.json", _assigns) do
    %{type: :access_denied}
  end

  @doc """
  This render will be used by-default for non-existent routes. You can use it in your controller:

        conn |> render("404.json", error_description)
  """
  def render("404.json", %{type: type}) when is_atom(type) or is_binary(type) do
    %{type: type}
  end

  def render("404.json", _assigns) do
    %{type: :not_found}
  end

  @doc """
  This render will be used by-default for internal errors. You can use it in your controller:

        conn |> render("500.json", error_description)
  """
  def render("500.json", %{type: type}) when is_atom(type) or is_binary(type) do
    %{type: type}
  end

  def render("500.json", _assigns) do
    %{type: :internal_error}
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
end
